import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase work');

    // Check if activities need to be uploaded
    final activitiesRef = FirebaseFirestore.instance.collection('activities');
    final snapshot = await activitiesRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      print('[INFO] No activities found. Uploading default activities...');
      await uploadActivitiesBatch(getDefaultActivities());
    } else {
      print('[INFO] Activities already exist in Firestore');
    }
  } catch (e) {
    print('ERROR');
  }
  runApp(const MyApp());
}


Future<void> uploadActivitiesBatch(List<Activity> activities) async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  for (var activity in activities) {
    final docRef = firestore.collection('activities').doc(activity.id);
    batch.set(docRef, activity.toMap());
  }

  try {
    await batch.commit();
    print('Firestore work');
  } catch (e) {
    print('Firestore error');
  }
}

Stream<List<Activity>> getActivitiesStream() {
  return FirebaseFirestore.instance
      .collection('activities')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = data['id'] ?? doc.id;
              return Activity.fromMap(data);
            })
            .toList();
      });
}

List<Activity> getDefaultActivities() {
  return [
    Activity(
      id: 'ac1',
      title: 'Planting trees in Central Park',
      description:
          'Help plant 100 saplings in Central Park. All ages are welcome.',
      location: 'Central Park',
      date: DateTime.now().add(const Duration(days: 5)),
      type: ActivityType.planting,
      distanceMeters: 850,
    ),
    Activity(
      id: 'ac2',
      title: 'Riverbank cleanup',
      description:
          'Let’s clean the riverbank and recycle the collected waste. Bring gloves if you have them.',
      location: 'Riverbank',
      date: DateTime.now().add(const Duration(days: 2)),
      type: ActivityType.cleanup,
      distanceMeters: 1200,
    ),
    Activity(
      id: 'ac3',
      title: 'Neighborhood sorting and recycling',
      description:
          'Join a recyclable waste sorting session in your neighborhood.',
      location: 'North District',
      date: DateTime.now().add(const Duration(days: 7)),
      type: ActivityType.recycling,
      distanceMeters: 600,
    ),
    Activity(
      id: 'ac4',
      title: 'Planting flowers in the park',
      description:
          'Together we plant flowers to beautify the city’s central park.',
      location: 'Youth Park',
      date: DateTime.now().add(const Duration(days: 10)),
      type: ActivityType.planting,
      distanceMeters: 2100,
    ),
    Activity(
      id: 'ac5',
      title: 'Forest cleanup',
      description:
          'Cleanup activity in the forest near the city. Equipment provided.',
      location: 'Green Forest',
      date: DateTime.now().add(const Duration(days: 14)),
      type: ActivityType.cleanup,
      distanceMeters: 4500,
    ),
    Activity(
      id: 'ac6',
      title: 'Challenge: 7 days without plastic',
      description: 'Take on the 7-day challenge and earn 15 points at the end.',
      location: 'Anywhere',
      date: DateTime.now(),
      type: ActivityType.challenge,
      distanceMeters: 0,
    ),
    Activity(
      id: 'ac7',
      title: 'Creative recycling workshop',
      description:
          'Turn waste into useful or decorative objects. Materials provided.',
      location: 'Cultural Center',
      date: DateTime.now().add(const Duration(days: 3)),
      type: ActivityType.recycling,
      distanceMeters: 900,
    ),
    Activity(
      id: 'ac8',
      title: 'Challenge: One week without a car',
      description:
          'Walk or cycle for 7 days and earn 20 points.',
      location: 'Anywhere',
      date: DateTime.now().add(const Duration(days: 1)),
      type: ActivityType.challenge,
      distanceMeters: 0,
    ),
  ];
}


Future<void> incrementCompletedActivities(String userId) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'completedActivities': FieldValue.increment(1),
    });
    print('[SUCCESS] Completed activities incremented for user $userId');
  } catch (e) {
    print('[ERROR] Failed to increment completed activities: $e');
  }
}


Future<void> decrementCompletedActivities(String userId) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'completedActivities': FieldValue.increment(-1),
    });
    print('completed activities for user $userId');
  } catch (e) {
    print('failed completed activities: $e');
  }
}


Future<void> addUserToActivity(String activityId, String userId) async {
  try {
    final actRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
    await actRef.update({
      'participantIds': FieldValue.arrayUnion([userId]),
      'participants': FieldValue.increment(1),
    });
    print('user $userId added to activity $activityId');
  } catch (e) {
    print('failed to add user to activity: $e');
  }
}

Future<void> removeUserFromActivity(String activityId, String userId) async {
  try {
    final actRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
    await actRef.update({
      'participantIds': FieldValue.arrayRemove([userId]),
      'participants': FieldValue.increment(-1),
    });
    print('user $userId removed from activity $activityId');
  } catch (e) {
    print('failed to remove user from activity: $e');
  }
}


bool isUserInActivity(Activity activity, String userId) {
  return activity.participantIds.contains(userId);
}

Future<void> rewardParticipants(
    String activityId, int pointsReward, List<String> participantIds) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();


    final actRef = firestore.collection('activities').doc(activityId);
    batch.update(actRef, {
      'isCompleted': true,
      'pointsReward': pointsReward,
    });


    for (String userId in participantIds) {
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'points': FieldValue.increment(pointsReward),
      });
    }


    await batch.commit();
    print('Rewarded ${participantIds.length} participants with $pointsReward points each');
  } catch (e) {
    print('Failed to reward participants: $e');
    rethrow;
  }
}


Future<void> convertPointsToBadges(
    String userId, int pointsToConvert, int badgesToAdd) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    // Get current user data
    final userDoc = await userRef.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final currentPoints = userData['points'] ?? 0;
    
    if (currentPoints < pointsToConvert) {
      throw Exception(
          'You do not have enough points. You have $currentPoints, you need $pointsToConvert');
    }
    

    await userRef.update({
      'points': FieldValue.increment(-pointsToConvert),
      'badges': FieldValue.increment(badgesToAdd),
    });
    
    print('Converted $pointsToConvert points to $badgesToAdd badges for user $userId');
  } catch (e) {
    print('Failed to convert points to badges: $e');
    rethrow;
  }
}


Future<void> buyShopItem(
    String userId, String itemId, int badgeCost, String itemName) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    // Get current user data
    final userDoc = await userRef.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final currentBadges = userData['badges'] ?? 0;
    
    if (currentBadges < badgeCost) {
      throw Exception(
          'You do not have enough badges. You have $currentBadges, you need $badgeCost');
    }
    
    // Update user badges
    await userRef.update({
      'badges': FieldValue.increment(-badgeCost),
    });
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .add({
      'itemName': itemName,
      'itemId': itemId,
      'cost': badgeCost,
      'currency': 'badges',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('User $userId purchased item $itemId for $badgeCost badges');
  } catch (e) {
    print('Failed to buy shop item: $e');
    rethrow;
  }
}


Future<void> joinRaffle(String userId, int badgeCost) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    // Get current user data
    final userDoc = await userRef.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final currentBadges = userData['badges'] ?? 0;
    
    if (currentBadges < badgeCost) {
      throw Exception(
          'You do not have enough badges. You have $currentBadges, you need $badgeCost');
    }
    
    await userRef.update({
      'badges': FieldValue.increment(-badgeCost),
    });
    
    // Add raffle entry
    await FirebaseFirestore.instance
        .collection('raffle_entries')
        .add({
      'userId': userId,
      'enteredAt': FieldValue.serverTimestamp(),
    });
    
    print('User $userId joined raffle');
  } catch (e) {
    print('Failed to join raffle: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecoline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Auth gate: show MainScaffold only when logged in and verified
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
            );
          }
          final user = snapshot.data;
          // If logged in and email verified → main app
          if (user != null && user.emailVerified) {
            return const MainScaffold();
          }
          // Otherwise → profile/auth screen (tab index 4)
          return const MainScaffold(initialIndex: 4);
        },
      ),
    );
  }
}


class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    ActivitiesScreen(),
    VolunteeringScreen(),
    EducationScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Activities'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
    BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Education'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
),

    );
  }

String _titleForIndex(int index) {
  switch (index) {
    case 0: return 'Home';
    case 1: return 'Activities';
    case 2: return 'Shop';
    case 3: return 'Education';
    case 4: return 'Profile';
    default: return 'Ecoline';
  }
}
}

enum ActivityType { planting, cleanup, recycling, challenge }

class Activity {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final ActivityType type;
  final int distanceMeters;
  final bool isJoined;
  final String? createdBy;
  final int participants;
  final DateTime? createdAt;
  final List<String> participantIds;
  final bool isCompleted;
  final int pointsReward;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.type,
    required this.distanceMeters,
    this.isJoined = false,
    this.createdBy,
    this.participants = 0,
    this.createdAt,
    this.participantIds = const [],
    this.isCompleted = false,
    this.pointsReward = 0,
  });

  Activity copyWith({
    bool? isJoined,
    List<String>? participantIds,
    bool? isCompleted,
    int? pointsReward,
  }) {
    return Activity(
      id: id,
      title: title,
      description: description,
      location: location,
      date: date,
      type: type,
      distanceMeters: distanceMeters,
      isJoined: isJoined ?? this.isJoined,
      createdBy: createdBy,
      participants: participants,
      createdAt: createdAt,
      participantIds: participantIds ?? this.participantIds,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsReward: pointsReward ?? this.pointsReward,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'distanceMeters': distanceMeters,
      'isJoined': isJoined,
      'createdBy': createdBy,
      'participants': participants,
      'participantIds': participantIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'isCompleted': isCompleted,
      'pointsReward': pointsReward,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _activityTypeFromString(map['type'] as String? ?? 'planting'),
      distanceMeters: map['distanceMeters'] as int? ?? 0,
      isJoined: map['isJoined'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
      participants: map['participants'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      isCompleted: map['isCompleted'] as bool? ?? false,
      pointsReward: map['pointsReward'] as int? ?? 0,
    );
  }

  static ActivityType _activityTypeFromString(String type) {
    switch (type) {
      case 'planting':
        return ActivityType.planting;
      case 'cleanup':
        return ActivityType.cleanup;
      case 'recycling':
        return ActivityType.recycling;
      case 'challenge':
        return ActivityType.challenge;
      default:
        return ActivityType.planting;
    }
  }
}


//HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _challengeJoined = false;

  void _toggleJoin(Activity activity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to participate')),
      );
      return;
    }

    try {
      if (isUserInActivity(activity, user.uid)) {
        await removeUserFromActivity(activity.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You left ${activity.title}')),
          );
        }
      } else {
        await addUserToActivity(activity.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You joined ${activity.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

 static const _featuredVolunteer = (
  title: 'Shopping for seniors',
  description: 'Help an elderly person buy groceries or medication.',
  category: 'Helping elderly people',
  organizer: 'Friendship Association',
);

static const _featuredArticle = (
  title: 'The power of challenges – how they change behavior',
  excerpt: 'Challenges turn passive users into active participants through clear goals.',
);

static const String _tipOfTheDay =
    '💡 Tip: Replace plastic bags with a reusable one. '
    'A single bag can replace up to 700 plastic bags over its lifetime!';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionBanner(
              color: cs.primaryContainer,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome to Ecoline! 🌿',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Discover activities, volunteering, and ecological education.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.eco, size: 48, color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 16),

          
            _SectionHeader(title: 'Tip of the day', icon: Icons.lightbulb_outline),
            const SizedBox(height: 6),
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(_tipOfTheDay,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 16),

            if (user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final completedActivities = (userData['completedActivities'] ?? 0) as int;
                  
                  return Column(
                    children: [
                      _SectionHeader(title: 'Active challenge', icon: Icons.flag_outlined),
                      const SizedBox(height: 6),
                      _ChallengeCard(
                        title: '7 days without plastic',
                        daysLeft: 7 - completedActivities,
                        totalDays: 7,
                        points: 15,
                        completedDays: completedActivities,
                        joined: _challengeJoined,
                        onJoin: () {
                          setState(() => _challengeJoined = !_challengeJoined);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_challengeJoined 
                               ? 'You accepted the challenge! 💪'
                                : 'You left the challenge.'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

            _SectionHeader(
                title: 'Recommended article', icon: Icons.book_outlined),
            const SizedBox(height: 6),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article_outlined, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_featuredArticle.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.green.shade800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_featuredArticle.excerpt,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Read the article'),
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Go to the Education section to read!')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SectionHeader(title: 'Your Points!', icon: Icons.handshake_outlined),
            const SizedBox(height: 6),
            if (user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final points = data['points'] ?? 0;
                  final completedActivities = (data['completedActivities'] ?? 0) as int;
                  
                  return Row(
                    children: [
                      _StatCard(
                        icon: Icons.star,
                        value: '$points',
                        label: 'Points',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        icon: Icons.check_circle,
                        value: '$completedActivities',
                        label: 'Activities',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        icon: Icons.local_fire_department,
                        value: '${completedActivities * 5}',
                        label: 'CO₂ Saved',
                        color: Colors.orange,
                      ),
                    ],
                  );
                },
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      value: '0',
                      label: 'Points',
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      value: '0',
                      label: 'Activities',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      value: '0',
                      label: 'CO₂ Saved',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



class _SectionBanner extends StatelessWidget {
  final Color color;
  final Widget child;
  const _SectionBanner({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final int daysLeft;
  final int totalDays;
  final int points;
  final bool joined;
  final int completedDays;
  final VoidCallback onJoin;

  const _ChallengeCard({
    required this.title,
    required this.daysLeft,
    required this.totalDays,
    required this.points,
    required this.joined,
    required this.completedDays,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final progress = completedDays / totalDays;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.deepPurple.shade800)),
                ),
                Chip(
                  label: Text('$points pct.',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.deepPurple.shade100,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Ziua $completedDays/$totalDays',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    color: Colors.deepPurple,
                    backgroundColor: Colors.deepPurple.shade100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$daysLeft zile rămase',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: joined ? Colors.grey : Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: onJoin,
                child: Text(joined ? 'You are already participating ✓' : 'Accept the challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 35),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


// ACTIVITY CARDURI
class ActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback onJoinPressed;

  const ActivityCard(
      {super.key, required this.activity, required this.onJoinPressed});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late TextEditingController _pointsController;
  bool _isRewardingLoading = false;

  @override
  void initState() {
    super.initState();
    _pointsController = TextEditingController();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  void _handleRewardParticipants() async {
    final pointsText = _pointsController.text.trim();
    if (pointsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter points to reward')),
      );
      return;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Points must be a positive number')),
      );
      return;
    }

    if (widget.activity.participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants to reward')),
      );
      return;
    }

    setState(() => _isRewardingLoading = true);

    try {
      await rewardParticipants(
        widget.activity.id,
        points,
        widget.activity.participantIds,
      );

      if (mounted) {
        _pointsController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Points awarded successfully to ${widget.activity.participantIds.length} participants!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rewarding participants: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRewardingLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isUserJoined =
        user != null && widget.activity.participantIds.contains(user.uid);
    final isCreator = user?.uid == widget.activity.createdBy;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.activity.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_labelForType(widget.activity.type),
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      _colorForType(widget.activity.type).withOpacity(0.15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.place, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(widget.activity.location,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey))),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_formatDate(widget.activity.date),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                if (widget.activity.distanceMeters > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.directions_walk,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text('${widget.activity.distanceMeters}m',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ]
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${widget.activity.participantIds.length} participant',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.grey.shade200,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUserJoined ? Colors.grey : null,
                    foregroundColor: isUserJoined ? Colors.white : null,
                  ),
                  onPressed: widget.onJoinPressed,
                  child: Text(isUserJoined ? 'Leave' : 'Participate'),
                ),
              ],
            ),
            // Creator reward section
            if (isCreator) ...[
              const SizedBox(height: 14),
              if (widget.activity.isCompleted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '✅ Activity Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🎁 Rewarded: ${widget.activity.pointsReward} points',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💰 Reward Participants',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pointsController,
                            keyboardType: TextInputType.number,
                            enabled: !_isRewardingLoading,
                            decoration: InputDecoration(
                              hintText: 'Points to reward',
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.grey, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isRewardingLoading
                              ? null
                              : _handleRewardParticipants,
                          icon: _isRewardingLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Reward'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelForType(ActivityType type) {
    switch (type) {
      case ActivityType.planting:
        return 'Plantare';
      case ActivityType.cleanup:
        return 'Curățenie';
      case ActivityType.recycling:
        return 'Reciclare';
      case ActivityType.challenge:
        return 'Provocare';
    }
  }

  Color _colorForType(ActivityType type) {
    switch (type) {
      case ActivityType.planting:
        return Colors.green;
      case ActivityType.cleanup:
        return Colors.blue;
      case ActivityType.recycling:
        return Colors.teal;
      case ActivityType.challenge:
        return Colors.deepPurple;
    }
  }
}

//ACTIVITY SCREEN
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _selectedDate;
  ActivityType _selectedType = ActivityType.planting;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleCreateActivity() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Add activity to Firestore and get the document reference
      final docRef = await FirebaseFirestore.instance
          .collection('activities')
          .add({
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'type': _selectedType.name,
        'distanceMeters': 0,
        'isJoined': false,
        'createdBy': user.uid,
        'participants': 0,
        'participantIds': [],
        'isCompleted': false,
        'pointsReward': 0,
        'createdAt': Timestamp.now(),
      });

      await docRef.update({'id': docRef.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create activity: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1B2E1C),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2E1C),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _buildLabel('Activity Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  validator: (v) => v?.isEmpty ?? true ? 'Title required' : null,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
                  decoration: InputDecoration(
                    hintText: 'e.g., Plant trees in the park',
                    hintStyle: const TextStyle(color: Color(0xFFB0BDB0), fontSize: 15),
                    prefixIcon: const Icon(Icons.edit, color: Color(0xFF8A9E8B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  validator: (v) => v?.isEmpty ?? true ? 'Description required' : null,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
                  decoration: InputDecoration(
                    hintText: 'Describe the activity...',
                    hintStyle: const TextStyle(color: Color(0xFFB0BDB0), fontSize: 15),
                    prefixIcon: const Icon(Icons.description, color: Color(0xFF8A9E8B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                _buildLabel('Location'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationCtrl,
                  validator: (v) => v?.isEmpty ?? true ? 'Location required' : null,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
                  decoration: InputDecoration(
                    hintText: 'e.g., Central Park',
                    hintStyle: const TextStyle(color: Color(0xFFB0BDB0), fontSize: 15),
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF8A9E8B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel('Activity Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE8EDE8), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF8A9E8B), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Select date'
                              : _selectedDate!.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedDate == null
                                ? const Color(0xFFB0BDB0)
                                : const Color(0xFF1B2E1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Activity Type
                _buildLabel('Activity Type'),
                const SizedBox(height: 8),
                DropdownButtonFormField<ActivityType>(
                  value: _selectedType,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                  items: ActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_labelForType(type)),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3A4E3B),
        letterSpacing: 0.2,
      ),
    );
  }

  String _labelForType(ActivityType type) {
    switch (type) {
      case ActivityType.planting:
        return 'Plantare';
      case ActivityType.cleanup:
        return 'Curățenie';
      case ActivityType.recycling:
        return 'Reciclare';
      case ActivityType.challenge:
        return 'Provocare';
    }
  }
}

// ACTIVITIES SCREEN
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  ActivityType? _selectedFilter;

  void _toggleJoin(Activity activity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to participate')),
      );
      return;
    }

    try {
      if (isUserInActivity(activity, user.uid)) {
        await removeUserFromActivity(activity.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have withdrawn from ${activity.title}')),
          );
        }
      } else {
        await addUserToActivity(activity.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have joined ${activity.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All activities',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedFilter == null,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = null),
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Planting',
                      selected: _selectedFilter == ActivityType.planting,
                      onSelected: (_) => setState(
                          () => _selectedFilter = ActivityType.planting),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Cleanup',
                      selected: _selectedFilter == ActivityType.cleanup,
                      onSelected: (_) => setState(
                          () => _selectedFilter = ActivityType.cleanup),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Recycling',
                      selected: _selectedFilter == ActivityType.recycling,
                      onSelected: (_) => setState(
                          () => _selectedFilter = ActivityType.recycling),
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Challenges',
                      selected: _selectedFilter == ActivityType.challenge,
                      onSelected: (_) => setState(
                          () => _selectedFilter = ActivityType.challenge),
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: StreamBuilder<List<Activity>>(
                  stream: getActivitiesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                      );
                    }

                    final activities = snapshot.data ?? [];
                    
                    // Filter activities based on selected type
                    final filtered = _selectedFilter == null
                        ? activities
                        : activities.where((a) => a.type == _selectedFilter).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('No activities available',
                            style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }

                    return Column(
                      children: [
                        Text('${filtered.length} activities',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final activity = filtered[index];
                              return ActivityCard(
                                activity: activity,
                                onJoinPressed: () => _toggleJoin(activity),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF2E7D32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddActivityScreen(),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.25),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}


// REWARDS SHOP SYSTEM
class VolunteeringScreen extends StatelessWidget {
  const VolunteeringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopHub();
  }
}

// Shop item model
class ShopItem {
  final String id;
  final String title;
  final String emoji;
  final int badgeCost;
  final String description;

  const ShopItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.badgeCost,
    required this.description,
  });
}

// Raffle entry model
class RaffleEntry {
  final String userId;
  final DateTime date;

  const RaffleEntry({required this.userId, required this.date});
}

// Main shop hub
class ShopHub extends StatefulWidget {
  const ShopHub({super.key});

  @override
  State<ShopHub> createState() => _ShopHubState();
}

class _ShopHubState extends State<ShopHub> {
  final List<ShopItem> _shopItems = const [
    ShopItem(
      id: 's1',
      title: 'EcoLine T-Shirt',
      emoji: '👕',
      badgeCost: 40,
      description: 'Official EcoLine t-shirt made from recycled material',
    ),
    ShopItem(
      id: 's2',
      title: 'Eco-friendly pen',
      emoji: '🖊️',
      badgeCost: 10,
      description: 'Pen made from biodegradable material',
    ),
    ShopItem(
      id: 's3',
      title: '50 RON Voucher',
      emoji: '🎁',
      badgeCost: 25,
      description: 'Voucher for partner stores',
    ),
    ShopItem(
      id: 's4',
      title: 'Volunteer Certificate',
      emoji: '🎓',
      badgeCost: 40,
      description: 'Official volunteer certificate',
    ),
    ShopItem(
      id: 's5',
      title: 'Raffle (500 RON)',
      emoji: '🎟️',
      badgeCost: 20,
      description: 'Chance to win in the monthly raffle',
    ),
  ];

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Shop', 0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('User Leaderboard', 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildShopTab()
                : const _LeaderboardView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildShopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          const _UserBalanceCard(),
          const SizedBox(height: 16),
          const _PointToBadgeConversion(),
          const SizedBox(height: 20),
          _buildSectionHeader('🛍️ Shop'),
          const SizedBox(height: 10),
          ..._shopItems.map((item) => _buildShopItemCard(item)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B2E1C),
        ),
      ),
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7B6C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '${item.badgeCost} badge',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: user != null
                        ? () => _handleBuyItem(item)
                        : null,
                    child: const Text(
                      'Buy',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBuyItem(ShopItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    try {
      await buyShopItem(user.uid, item.id, item.badgeCost, item.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} purchased successfully! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

//User balance card
class _UserBalanceCard extends StatelessWidget {
  const _UserBalanceCard();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
          : Stream.empty(),
      builder: (context, snapshot) {
        final userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final points = userData['points'] ?? 0;
        final badges = userData['badges'] ?? 0;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: const Color(0xFF2E7D32).withOpacity(0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      '⭐ Points',
                      style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 210, 228, 212)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 243, 255, 244),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Column(
                  children: [
                    const Text(
                      '🎖️ Badges',
                      style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 210, 228, 212)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$badges',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 243, 255, 244),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//Point to badge conversion
class _PointToBadgeConversion extends StatefulWidget {
  const _PointToBadgeConversion();

  @override
  State<_PointToBadgeConversion> createState() =>
      _PointToBadgeConversionState();
}

class _PointToBadgeConversionState extends State<_PointToBadgeConversion> {
  final List<(int, int)> _conversions = [
    (25, 5),
    (70, 15),
    (100, 20),
    (200, 50),
  ];

  bool _isLoading = false;

  void _handleConversion(int points, int badges) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await convertPointsToBadges(user.uid, points, badges);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ You converted $points points into $badges badges!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔄 Convert points → badges',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2E1C),
          ),
        ),
        const SizedBox(height: 10),
        ..._conversions.map((conv) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⭐ ${conv.$1} points → 🎖️ ${conv.$2} badges',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _handleConversion(conv.$1, conv.$2),
                        child: const Text(
                          'Convert',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

//Leaderboard view
class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users in the leaderboard yet'),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final userData = docs[index].data() as Map<String, dynamic>;
            final rank = index + 1;
            final name = userData['displayName'] ?? 'User';
            final points = userData['points'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getRankColor(rank),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2E1C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${userData['completedActivities'] ?? 0} activities',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7B6C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '⭐ $points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF2E7D32);
    }
  }
}

// EDUCATION SCREEN
class Article {
  final String id;
  final String title;
  final String content;
  final String excerpt;

  Article(
      {required this.id,
      required this.title,
      required this.content,
      required this.excerpt});
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  static final List<Article> _articles = [
    Article(
      id: 'art1',
      title:
          'Why daily content matters (articles, tips & tricks, challenges)',
      excerpt:
          'Daily content keeps users engaged, builds habits, and turns information into action.',
      content:
          'In a modern app, content is not just "something to read" it is the engine that keeps users engaged and active.\n\n'
          '1. Builds habits\nWhen users receive daily articles or challenges, they begin to develop healthy routines.\n\n'
          '2. Continuous education\nArticles deliver useful information in a simple and accessible way.\n\n'
          '3. Increased engagement\nQuick tips & tricks are easy to consume and provide immediate value.\n\n'
          '4. Motivation through action\nChallenges turn theory into practice.',
    ),
    Article(
      id: 'art2',
      title: 'The power of challenges – how they change user behaviour',
      excerpt:
          'Challenges turn passive users into active participants through clear goals and fast feedback.',
      content:
          'Challenges are one of the most effective methods of turning passive users into active participants.\n\n'
          '1. Easy to understand\nA challenge like "7 days without plastic" is simple and clear.\n\n'
          '2. Creates a purpose\nUsers have a concrete goal to work towards.\n\n'
          '3. Provides quick satisfaction\nEvery completed day gives a sense of progress.',
    ),
    Article(
      id: 'art3',
      title: 'How to build sustainable habits in everyday life',
      excerpt: 'Small habits, repeated daily, lead to big changes over time.',
      content:
          'Big changes start with small steps. Sustainable habits are the key to a responsible lifestyle.\n\n'
          '1. Start simple\n2. Be consistent\n3. Set clear goals\n4. Track your progress',
    ),
    Article(
      id: 'art4',
      title: 'Why recycling matters more than you think',
      excerpt: 'Recycling helps the environment, saves resources, and reduces pollution.',
      content:
          'Recycling is one of the simplest ways you can help the planet.\n\n'
          '1. Reduces waste\n2. Saves resources\n3. Protects nature\n4. Creates a real impact',
    ),
    Article(
      id: 'art5',
      title: 'How to motivate yourself to volunteer',
      excerpt: 'Volunteering brings personal satisfaction and helps the community.',
      content:
          'Volunteering does not just mean helping — it means growing.\n\n'
          '1. Help the people around you\n2. Develop your skills\n3. Gain personal satisfaction\n4. Build new connections',
    ),
    Article(
      id: 'art6',
      title: 'Understanding your carbon footprint and how to reduce it',
      excerpt:
          'Your carbon footprint is the total greenhouse gas emissions caused by your actions. Understanding it is the first step to reducing it.',
      content:
          'Every choice you make — from what you eat to how you travel contributes to your personal carbon footprint. '
          'A carbon footprint measures the total amount of greenhouse gases, primarily carbon dioxide and methane, that your activities release into the atmosphere. '
          'While it can feel overwhelming, reducing your footprint is more achievable than you might think.\n\n'
          '1. What is a carbon footprint?\n'
          'Your carbon footprint covers direct emissions, like driving a car or heating your home with gas, and indirect emissions, '
          'like the energy used to produce the food you eat or the clothes you buy. '
          'The average person produces around 4 to 8 tonnes of CO₂ per year, depending on their country and lifestyle.\n\n'
          '2. Transport is the biggest factor\n'
          'Flights and car journeys account for a large share of most people\'s footprint. '
          'Choosing to cycle, walk, or take public transport even a few times a week can make a measurable difference. '
          'If you must drive, consider carpooling or switching to an electric vehicle.\n\n'
          '3. Food choices matter enormously\n'
          'Meat and dairy production generates far more emissions than growing vegetables or grains. '
          'You do not need to become fully vegetarian overnight — simply reducing red meat consumption to two or three times a week '
          'can cut your food-related emissions by up to 30%. Buying locally grown, seasonal produce also helps by shortening supply chains.\n\n'
          '4. Energy at home\n'
          'Heating and cooling your home is a major source of emissions. Simple changes like insulating your walls, '
          'switching to LED bulbs, and unplugging devices on standby all add up. '
          'If your energy provider offers a green tariff powered by renewables, consider making the switch.\n\n'
          '5. The power of conscious consumption\n'
          'Fast fashion and throwaway electronics place a huge burden on the planet. '
          'Buying second-hand, repairing instead of replacing, and choosing products with longer lifespans are all powerful acts. '
          'Ask yourself before any purchase: do I truly need this, and can I find it used?\n\n'
          '6. Track and improve\n'
          'Use a free online carbon calculator to measure your current footprint. '
          'Set a realistic goal to reduce it by 10% over the next six months. '
          'Small, consistent actions compound over time — and every tonne of CO₂ you avoid releasing is a genuine contribution to a healthier planet.',
    ),
    Article(
      id: 'art7',
      title: 'The hidden environmental cost of our digital lives',
      excerpt:
          'Streaming videos, sending emails, and storing data in the cloud all consume real energy. Learn how to make your digital habits greener.',
      content:
          'It is easy to think of digital activity as clean and weightless — after all, you cannot see a stream of data. '
          'But every email you send, every video you stream, and every file you store in the cloud requires physical infrastructure: '
          'servers, cooling systems, and data centres that run around the clock and consume enormous amounts of electricity.\n\n'
          '1. How big is the digital carbon footprint?\n'
          'The global internet and its supporting infrastructure currently account for roughly 3.7% of global greenhouse gas emissions — '
          'comparable to the aviation industry. This figure is expected to double by 2025 as data consumption continues to grow. '
          'A single hour of video streaming produces around 36 grams of CO₂, and the world watches over a billion hours of online video every day.\n\n'
          '2. Email and messaging\n'
          'A standard email without attachments produces about 4 grams of CO₂. '
          'An email with a large attachment can produce up to 50 grams. '
          'Spam emails alone generate around 33 billion kilowatt-hours of energy per year globally. '
          'Unsubscribing from newsletters you never read and deleting old emails from cloud servers are small but genuinely useful steps.\n\n'
          '3. Streaming habits\n'
          'Streaming quality has a direct impact on energy use. Watching in standard definition rather than 4K uses up to four times less data '
          'and, by extension, significantly less energy. Downloading content to watch offline is often more efficient than streaming repeatedly. '
          'Turning off autoplay features also prevents content from running unnecessarily.\n\n'
          '4. Cloud storage and device use\n'
          'Storing large volumes of data — especially duplicate photos and old files — in the cloud keeps servers working harder. '
          'Regularly reviewing and deleting files you no longer need lightens the load on data centres. '
          'Extending the life of your devices is equally important: manufacturing a new smartphone produces around 70 kg of CO₂, '
          'so keeping your phone for three years instead of two makes a real difference.\n\n'
          '5. Search engines and AI tools\n'
          'A single internet search uses a small but non-zero amount of energy. '
          'AI-powered tools and large language model queries can consume significantly more energy than a standard search. '
          'Being intentional about how often and how efficiently you use these tools is a growing consideration.\n\n'
          '6. What you can do\n'
          'Choose energy-efficient devices and enable power-saving modes. '
          'Stream at lower resolutions when picture quality does not matter. '
          'Delete old emails, unused apps, and duplicate files regularly. '
          'Support companies that power their data centres with renewable energy. '
          'Every digital habit you refine is a step toward a lighter, greener online world.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.separated(
          itemCount: _articles.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Education & Challenges',
                    style: Theme.of(context).textTheme.titleLarge),
              );
            }
            final article = _articles[index - 1];
            return ArticleCard(
              article: article,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ArticleDetail(article: article)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(article.excerpt,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onTap, child: const Text('Read')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleDetail extends StatelessWidget {
  final Article article;

  const ArticleDetail({super.key, required this.article});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(article.content,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Center(
                  child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'))),
            ],
          ),
        ),
      ),
    );
  }
}
//PROFILE SCREEN
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  void _onLoginSuccess() {
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }

        final user = snapshot.data;

        // Show logged-out state if no user OR email not yet verified
        if (user == null || !user.emailVerified) {
          return _buildLoggedOut(context);
        }

        return _buildLoggedIn(context, user);
      },
    );
  }

  //NOT LOGGED IN
  Widget _buildLoggedOut(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome to Ecoline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B2E1C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the community and make\na difference for our planet 🌍',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Color(0xFF6B7B6C), height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(onLoginSuccess: _onLoginSuccess),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Login',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SignupScreen(onSignupSuccess: _onLoginSuccess),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(
                        color: Color(0xFF2E7D32), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//LOGGED IN


  Stream<int> _getUserActivitiesCount(String userId) {
    return FirebaseFirestore.instance
        .collection('activities')
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.where((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>?;
              final participantIds = List<String>.from(data?['participantIds'] as List? ?? []);
              return participantIds.contains(userId);
            } catch (e) {
              print('Error in _getUserActivitiesCount: $e');
              return false;
            }
          }).length;
          print('✅ Activities count for $userId: $count');
          return count;
        });
  }

  Widget _buildLoggedIn(BuildContext context, User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {  
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }

        final userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final points = userData['points'] ?? 0;
        final badges = userData['badges'] ?? 0;
        final displayName =
            userData['displayName'] ?? user.displayName ?? user.email ?? 'User';

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? '',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '$points points',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<int>(
                  stream: _getUserActivitiesCount(user.uid),
                  initialData: 0,
                  builder: (context, activitiesSnapshot) {
                    final activitiesCount = activitiesSnapshot.data ?? 0;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('🌱', '$points', 'Points'),
                          const SizedBox(width: 12),
                          _buildStatCard('🤝', '$activitiesCount', 'Activities'),
                          const SizedBox(width: 12),
                          _buildStatCard('🏆', '$badges', 'Insigne'),
                        ],
                      ),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎁 Your bought items',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2E1C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('purchases')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final purchases = snapshot.data!.docs;

                          if (purchases.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Nu ai cumpărat niciun articol încă',
                                  style: TextStyle(color: Color(0xFF6B7B6C)),
                                ),
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: purchases.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, index) {
                                final purchase = purchases[index].data() as Map<String, dynamic>;
                                final itemName = purchase['itemName'] ?? 'Item';
                                final cost = purchase['cost'] ?? 0;
                                final createdAt = (purchase['createdAt'] as Timestamp?)?.toDate();
                                final formattedDate = createdAt != null
                                    ? '${createdAt.day} ${_getMonthName(createdAt.month)}'
                                    : 'N/A';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B2E1C),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$cost insigne • $formattedDate',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7B6C),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About EcoLine',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AboutScreen()),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2E1C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7B6C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final textColor =
        isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1B2E1C);

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFB0BDB0),
        size: 20,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, indent: 72, endIndent: 0, color: Color(0xFFF0F0F0));
  }

  String _getMonthName(int month) {
    const months = [
      'Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun',
      'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }
}


// ABOUT SCREEN


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1B2E1C),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About EcoLine',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2E1C),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo or Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'EcoLine',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B2E1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A9E8B),
                ),
              ),
              const SizedBox(height: 24),
              
              // About Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This App',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'EcoLine is a community-driven platform that connects people with environmental activities. Join volunteers and make a real impact on our planet through easy-to-join activities like planting trees, cleaning up our communities, and participating in eco-challenges.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: Color(0xFF6B7B6C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Features
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Features',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('🎯', 'Find Environmental Activities'),
                    _buildFeatureItem('🤝', 'Join Volunteering Opportunities'),
                    _buildFeatureItem('✨', 'Earn Points & Badges'),
                    _buildFeatureItem('📚', 'Learn Environmental Tips'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Contact
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Get in Touch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2E1C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Email: support@ecoline.app\nWebsite: www.ecoline.app',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7B6C),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7B6C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//HELP ANd SUPPORT SCREEN
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1B2E1C),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2E1C),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQSection(
                'Getting Started',
                [
                  (
                    'How do I join an activity?',
                    'Browse the Activities tab, find an activity you like, and tap the "Join" button. You\'ll receive updates about the activity.'
                  ),
                  (
                    'How do I earn points?',
                    'Complete activities and challenges to earn points. The more you participate, the more points you accumulate.'
                  ),
                  (
                    'What are challenges?',
                    'Challenges are 7-day or longer environmental goals that test your commitment. Complete them to earn bonus points.'
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFAQSection(
                'Account & Profile',
                [
                  (
                    'Can I change my username?',
                    'Yes, go to Settings > Edit Profile to change your display name.'
                  ),
                  (
                    'How do I reset my password?',
                    'On the login screen, tap "Forgot Password" and follow the instructions sent to your email.'
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFAQSection(
                'Volunteering',
                [
                  (
                    'How do I find volunteering opportunities?',
                    'Go to the Volunteering tab and browse available opportunities by category.'
                  ),
                  (
                    'How do I contact an organization?',
                    'Tap on an opportunity and select "Contact Organizer" to see their phone and email.'
                  ),
                  (
                    'Can I volunteer remotely?',
                    'Some opportunities may allow remote participation. Check the opportunity description for details.'
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildContactSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(String title, List<(String, String)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B2E1C),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildFAQItem(items[i].$1, items[i].$2),
                if (i < items.length - 1)
                  const Divider(
                    height: 0,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B2E1C),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF6B7B6C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded,
                  color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'Still Need Help?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If you can\'t find the answer you\'re looking for, please contact our support team:',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6B7B6C),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Email: support@ecoline.app\nResponse time: Usually within 24 hours',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}


//SETTINGS SCREEN

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


  void _showChangeUsername(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE3DD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Change Username',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2E1C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This is the name shown on your profile.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7B6C)),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF1B2E1C)),
                    decoration: InputDecoration(
                      labelText: 'New Username',
                      labelStyle:
                          const TextStyle(color: Color(0xFF6B7B6C)),
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          color: Color(0xFF8A9E8B), size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8EDE8), width: 1.5)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8EDE8), width: 1.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF2E7D32), width: 1.8)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFD32F2F), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      if (v.trim().length < 2) {
                        return 'Username must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isLoading = true);

                              try {
                                final user =
                                    FirebaseAuth.instance.currentUser!;
                                final newName = ctrl.text.trim();

                                // Update Firebase Auth display name
                                await user.updateDisplayName(newName);

                                // Update Firestore
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'displayName': newName});

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Username updated! ✅'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ));
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text('Failed to update username.'),
                                    backgroundColor: Color(0xFFD32F2F),
                                  ));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF2E7D32).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Save Username',
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 //Change Password
  void _showChangePassword(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String errorMsg = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE3DD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2E1C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your current password to confirm your identity.',
                    style:
                        TextStyle(fontSize: 13.5, color: Color(0xFF6B7B6C)),
                  ),
                  const SizedBox(height: 20),

                  // Current password
                  _buildPasswordField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    obscure: obscureCurrent,
                    onToggle: () =>
                        setModalState(() => obscureCurrent = !obscureCurrent),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // New password
                  _buildPasswordField(
                    controller: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter a new password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm new password
                  _buildPasswordField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setModalState(() => obscureConfirm = !obscureConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (v != newCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  if (errorMsg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        border: Border.all(
                            color: const Color(0xFFEF5350), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(errorMsg,
                          style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                isLoading = true;
                                errorMsg = '';
                              });

                              try {
                                final user =
                                    FirebaseAuth.instance.currentUser!;

                                // Re-authenticate with current password
                                final credential =
                                    EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: currentCtrl.text,
                                );
                                await user.reauthenticateWithCredential(
                                    credential);

                                // Update to new password
                                await user.updatePassword(newCtrl.text);

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Password updated! ✅'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ));
                                }
                              } on FirebaseAuthException catch (e) {
                                String msg;
                                switch (e.code) {
                                  case 'wrong-password':
                                  case 'invalid-credential':
                                    msg = 'Current password is incorrect.';
                                    break;
                                  case 'weak-password':
                                    msg = 'New password is too weak.';
                                    break;
                                  case 'requires-recent-login':
                                    msg =
                                        'Session expired. Please log out and log in again.';
                                    break;
                                  default:
                                    msg = e.message ??
                                        'Failed to update password.';
                                }
                                setModalState(() {
                                  isLoading = false;
                                  errorMsg = msg;
                                });
                              } catch (_) {
                                setModalState(() {
                                  isLoading = false;
                                  errorMsg =
                                      'An unexpected error occurred.';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF2E7D32).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Update Password',
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7B6C), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF8A9E8B), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF8A9E8B),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF2E7D32), width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final displayName = userData['displayName'] ??
            user?.displayName ??
            user?.email ??
            'User';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF1B2E1C),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2E1C),
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Change Username',
                          subtitle: displayName,
                          onTap: () =>
                              _showChangeUsername(context, displayName),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () => _showChangePassword(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('Account Info'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: user?.email ?? '—',
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Email Verified',
                          value: (user?.emailVerified ?? false)
                              ? 'Yes ✅'
                              : 'No ❌',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A9E8B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2E1C))),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12.5, color: Color(0xFF8A9E8B))),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFB0BDB0), size: 20),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF6B7B6C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6B7B6C), size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2E1C))),
      trailing: Text(value,
          style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF6B7B6C),
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, indent: 72, endIndent: 0, color: Color(0xFFF0F0F0));
  }
}

//LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        await userCredential.user?.sendEmailVerification();
        setState(() {
          _errorMessage =
              'Please verify your email before logging in. A new link has been sent.';
          _isLoading = false;
        });
        return;
      }

      // Ensure Firestore doc exists
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'points': 0,
          'badges': 0,
          'completedActivities': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        widget.onLoginSuccess?.call();
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMsg = 'Incorrect email or password.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMsg = e.message ?? 'Login failed. Please try again.';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter your email'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: ctrl.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password reset email sent!')));
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to send reset email.')));
                  }
                }
              }
            },
            child: const Text('Send',
                style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1B2E1C),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Login',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2E1C),
                        letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text('Good to see you again 👋',
                    style:
                        TextStyle(fontSize: 15, color: Color(0xFF6B7B6C))),
                const SizedBox(height: 36),
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordCtrl,
                  hint: '••••••••',
                  obscure: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF8A9E8B),
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(
                          color: const Color(0xFFEF5350), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage,
                        style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Forgot password?',
                        style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF2E7D32).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Login',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(
                            color: Color(0xFF6B7B6C), fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignupScreen(
                              onSignupSuccess: widget.onLoginSuccess),
                        ),
                      ),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A4E3B),
          letterSpacing: 0.2));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFB0BDB0), fontSize: 15),
        prefixIcon:
            Icon(prefixIcon, color: const Color(0xFF8A9E8B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF2E7D32), width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}


//SIGN UP SCREEN

class SignupScreen extends StatefulWidget {
  final VoidCallback? onSignupSuccess;
  const SignupScreen({super.key, this.onSignupSuccess});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(_nameCtrl.text.trim());

      // Create Firestore doc with points = 0 and completedActivities = 0
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': _emailCtrl.text.trim(),
        'displayName': _nameCtrl.text.trim(),
        'points': 0,
        'badges': 0,
        'completedActivities': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.mark_email_read_rounded,
                  color: Color(0xFF2E7D32), size: 28),
              SizedBox(width: 10),
              Text('Verify your email'),
            ]),
            content: Text(
              'A verification link has been sent to ${_emailCtrl.text.trim()}.\n\nPlease verify before logging in.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                          onLoginSuccess: widget.onSignupSuccess),
                    ),
                  );
                },
                child: const Text('Go to Login',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'weak-password':
          errorMsg = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          errorMsg = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Account creation is currently disabled.';
          break;
        default:
          errorMsg = e.message ?? 'Signup failed. Please try again.';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1B2E1C),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2E1C),
                        letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text('Start your eco journey today 🌱',
                    style:
                        TextStyle(fontSize: 15, color: Color(0xFF6B7B6C))),
                const SizedBox(height: 36),
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: 'Jane Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordCtrl,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF8A9E8B),
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter a password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(
                          color: const Color(0xFFEF5350), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage,
                        style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                const Text(
                  'By signing up, you agree to our Terms of Service\nand Privacy Policy.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8A9E8B),
                      height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF2E7D32).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Sign Up',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(
                            color: Color(0xFF6B7B6C), fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Login',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A4E3B),
          letterSpacing: 0.2));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1B2E1C)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFB0BDB0), fontSize: 15),
        prefixIcon:
            Icon(prefixIcon, color: const Color(0xFF8A9E8B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE8EDE8), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF2E7D32), width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
