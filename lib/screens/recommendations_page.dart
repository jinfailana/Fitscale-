// lib/screens/recommendations_page.dart
import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../models/user_model.dart';
import '../utils/recommendation_logic.dart' as workout_logic;
import 'workout_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation/custom_navbar.dart';
import '../SummaryPage/summary_page.dart';
import '../HistoryPage/history.dart';
import '../utils/custom_page_route.dart';
import '../SummaryPage/manage_acc.dart';

class RecommendationsPage extends StatefulWidget {
  final UserModel user;

  const RecommendationsPage({super.key, required this.user});

  @override
  _RecommendationsPageState createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  int selectedTabIndex = 0;
  int _selectedIndex = 1;
  List<WorkoutPlan> myWorkouts = [];

  @override
  void initState() {
    super.initState();
    _fetchMyWorkouts();
  }

  Future<void> _fetchMyWorkouts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final workoutsCollection = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .get();

        setState(() {
          myWorkouts = workoutsCollection.docs.map((doc) {
            final data = doc.data();
            return WorkoutPlan(
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              icon: IconData(data['iconCode'] ?? 0xe1d8,
                  fontFamily: 'MaterialIcons'),
              exercises: (data['exercises'] as List<dynamic>? ?? [])
                  .map((e) => Exercise(
                        name: e['name'] ?? '',
                        sets: e['sets'] ?? '',
                        reps: e['reps'] ?? '',
                        rest: e['rest'] ?? '',
                        icon: IconData(e['iconCode'] ?? 0xe1d8,
                            fontFamily: 'MaterialIcons'),
                        musclesWorked:
                            List<String>.from(e['musclesWorked'] ?? []),
                        instructions:
                            List<String>.from(e['instructions'] ?? []),
                        gifUrl: e['gifUrl'] ?? '',
                      ))
                  .toList(),
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching workouts: $e');
    }
  }

  Future<void> addToMyWorkouts(WorkoutPlan workout) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if workout already exists
        final existingWorkouts = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('name', isEqualTo: workout.name)
            .get();

        if (existingWorkouts.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Workout is Already in My Workouts'),
              backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
            ),
          );
          return;
        }

        // Add to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .add({
          'name': workout.name,
          'description': workout.description,
          'iconCode': workout.icon.codePoint,
          'exercises': workout.exercises
              .map((e) => {
                    'name': e.name,
                    'sets': e.sets,
                    'reps': e.reps,
                    'rest': e.rest,
                    'iconCode': e.icon.codePoint,
                    'musclesWorked': e.musclesWorked,
                    'instructions': e.instructions,
                    'gifUrl': e.gifUrl,
                  })
              .toList(),
        });

        // Update local state
        setState(() {
          if (!myWorkouts.contains(workout)) {
            myWorkouts.add(workout);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout Added Successfully'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );
      }
    } catch (e) {
      print('Error adding workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add workout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeFromMyWorkouts(WorkoutPlan workout) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(44, 44, 46, 1.0),
          title: const Text(
            'Remove Workout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this workout? All progress tracking data will also be deleted.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // User cancelled the removal
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Find and remove from Firestore
        final workoutsCollection = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('name', isEqualTo: workout.name)
            .get();

        for (var doc in workoutsCollection.docs) {
          await doc.reference.delete();
        }

        // Delete workout history for this workout
        final historyCollection = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .where('workoutName', isEqualTo: workout.name)
            .get();

        for (var doc in historyCollection.docs) {
          await doc.reference.delete();
        }

        // Update local state
        setState(() {
          myWorkouts.removeWhere((w) => w.name == workout.name);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout and progress history removed successfully'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );
      }
    } catch (e) {
      print('Error removing workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error removing workout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<WorkoutPlan> _getAllPossibleWorkouts() {
    // Get all possible workouts regardless of user preferences
    List<WorkoutPlan> allWorkouts = [];

    // Add weight loss workouts
    allWorkouts.addAll(workout_logic.getWeightLossWorkouts(
      intensity: "intermediate",
      hasGymAccess: true,
      equipment: [
        "Dumbbells",
        "Barbells",
        "Kettlebells",
        "Cable Machine",
        "Bench",
        "Pull-up Bar",
      ],
      calorieTarget: 2000,
      duration: "45 min",
    ));

    allWorkouts.addAll(workout_logic.getWeightLossWorkouts(
      intensity: "intermediate",
      hasGymAccess: false,
      equipment: [],
      calorieTarget: 2000,
      duration: "45 min",
    ));

    // Add muscle gain workouts
    allWorkouts.addAll(workout_logic.getMuscleGainWorkouts(
      intensity: "intermediate",
      hasGymAccess: true,
      equipment: [
        "Dumbbells",
        "Barbells",
        "Cable Machine",
        "Bench",
        "Pull-up Bar",
      ],
      duration: "45 min",
    ));

    allWorkouts.addAll(workout_logic.getMuscleGainWorkouts(
      intensity: "intermediate",
      hasGymAccess: false,
      equipment: [],
      duration: "45 min",
    ));

    // Add general fitness workouts
    allWorkouts.addAll(workout_logic.getGeneralFitnessWorkouts(
      intensity: "intermediate",
      hasGymAccess: true,
      equipment: [
        "Dumbbells",
        "Kettlebells",
        "Medicine Ball",
        "TRX",
      ],
      duration: "45 min",
    ));

    allWorkouts.addAll(workout_logic.getGeneralFitnessWorkouts(
      intensity: "intermediate",
      hasGymAccess: false,
      equipment: [],
      duration: "45 min",
    ));

    // Add cardio workouts
    allWorkouts.add(workout_logic.getCardioWorkout(
      intensity: "intermediate",
      hasGymAccess: true,
      equipment: ["Treadmill", "Rowing Machine", "Exercise Bike"],
      duration: "45 min",
    ));

    allWorkouts.add(workout_logic.getCardioWorkout(
      intensity: "intermediate",
      hasGymAccess: false,
      equipment: [],
      duration: "45 min",
    ));

    // Add strength workouts
    allWorkouts.add(workout_logic.getStrengthWorkout(
      intensity: "intermediate",
      hasGymAccess: true,
      equipment: [
        "Dumbbells",
        "Barbells",
        "Cable Machine",
      ],
      duration: "45 min",
    ));

    allWorkouts.add(workout_logic.getStrengthWorkout(
      intensity: "intermediate",
      hasGymAccess: false,
      equipment: [],
      duration: "45 min",
    ));

    return allWorkouts;
  }

  List<WorkoutPlan> _getCurrentWorkouts() {
    switch (selectedTabIndex) {
      case 0:
        // Get current recommendations and filter out workouts that are already in My Workouts
        List<WorkoutPlan> recommendations =
            workout_logic.generateRecommendations(widget.user);
        return recommendations.where((workout) {
          return !myWorkouts.any((myWorkout) => myWorkout.name == workout.name);
        }).toList();
      case 1:
        return myWorkouts;
      case 2:
        // Get all possible workouts
        List<WorkoutPlan> allWorkouts = _getAllPossibleWorkouts();
        // Get current recommendations
        List<WorkoutPlan> recommendations =
            workout_logic.generateRecommendations(widget.user);

        // Filter out workouts that are already in recommendations or My Workouts
        return allWorkouts.where((workout) {
          return !recommendations.any((recommended) =>
                  recommended.name == workout.name &&
                  recommended.description == workout.description) &&
              !myWorkouts.any((myWorkout) => myWorkout.name == workout.name);
        }).toList();
      default:
        return [];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const SummaryPage(),
          transitionType: TransitionType.leftToRight,
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const HistoryPage(),
          transitionType: TransitionType.rightToLeft,
        ),
      );
    } else if (index == 3) {
      // Show profile modal - this is handled in the CustomNavBar
    }
    // No need to handle index 1 (current page)
  }

  void _showProfileModal(BuildContext context) async {
    // Pre-fetch user data before showing the modal
    final user = FirebaseAuth.instance.currentUser;
    String username = 'User';
    String email = user?.email ?? '';

    // Fetch user data synchronously before showing the modal
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          username = doc['username'] ?? 'User';
          email = user.email ?? '';
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    // Now show the modal with the pre-fetched data
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(28, 28, 30, 1.0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFFDF4D0F),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // User profile card
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close the modal first
                    Navigator.push(
                      context,
                      CustomPageRoute(child: const ManageAccPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(28, 28, 30, 1.0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDF4D0F)),
                    ),
                    child: Row(
                      children: [
                        // Profile picture
                        const CircleAvatar(
                          backgroundColor:
                              Color.fromRGBO(223, 77, 15, 0.2),
                          radius: 20,
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFDF4D0F),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // My Device option
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Handle device settings
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(28, 28, 30, 1.0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDF4D0F)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.devices,
                          color: Color(0xFFDF4D0F),
                          size: 24,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'My Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
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

  Future<void> _loadAndNavigateToRecommendations() async {
    // Already on recommendations page, so no need to navigate
  }

  @override
  Widget build(BuildContext context) {
    List<WorkoutPlan> currentWorkouts = _getCurrentWorkouts();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECOMMENDED WORKOUT',
                style: TextStyle(
                  color: Color(0xFFDF4D0F),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's start your activities!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(44, 44, 46, 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromRGBO(60, 60, 62, 1.0),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('Recommended', 0),
                    _buildTabButton('My Workouts', 1),
                    _buildTabButton('Other', 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedTabIndex == 1 && myWorkouts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(223, 77, 15, 0.1),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color.fromRGBO(223, 77, 15, 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Color.fromRGBO(223, 77, 15, 0.7),
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Added Workouts Yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              child: const Text(
                                'Add workouts from the Recommended tab to build your personal collection',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: currentWorkouts.length,
                        itemBuilder: (context, index) {
                          final plan = currentWorkouts[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(44, 44, 46, 1.0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromRGBO(223, 77, 15, 1.0),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            223, 77, 15, 0.2),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Icon(
                                        plan.icon,
                                        color: const Color.fromRGBO(
                                            223, 77, 15, 1.0),
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            plan.description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (selectedTabIndex == 1)
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: TextButton(
                                          onPressed: () =>
                                              removeFromMyWorkouts(plan),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: Colors.red
                                                      .withOpacity(0.3)),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  color: Colors.red, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Remove',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            CustomPageRoute(
                                              child: WorkoutDetailsPage(
                                                workout: plan,
                                                onAddToWorkoutList:
                                                    addToMyWorkouts,
                                              ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color.fromRGBO(
                                              223, 77, 15, 0.1),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: const BorderSide(
                                                color: Color.fromRGBO(
                                                    223, 77, 15, 0.3)),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.fitness_center,
                                                color: Color.fromRGBO(
                                                    223, 77, 15, 1.0),
                                                size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'Details',
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    223, 77, 15, 1.0),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        showProfileModal: _showProfileModal,
        loadAndNavigateToRecommendations: _loadAndNavigateToRecommendations,
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(223, 77, 15, 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color.fromRGBO(223, 77, 15, 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
