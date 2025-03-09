// lib/screens/recommendations_page.dart
import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../models/user_model.dart';
import '../utils/recommendation_logic.dart' as workout_logic;
import 'workout_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                  })
              .toList(),
        });

        // Update local state
        setState(() {
          if (!myWorkouts.contains(workout)) {
            myWorkouts.add(workout);
          }
        });
      }
    } catch (e) {
      print('Error adding workout: $e');
    }
  }

  Future<void> removeFromMyWorkouts(WorkoutPlan workout) async {
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

        // Update local state
        setState(() {
          myWorkouts.removeWhere((w) => w.name == workout.name);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout removed successfully'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );
      }
    } catch (e) {
      print('Error removing workout: $e');
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
      duration: "45 min",
    ));

    allWorkouts.add(workout_logic.getCardioWorkout(
      intensity: "intermediate",
      hasGymAccess: false,
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
        return workout_logic.generateRecommendations(widget.user);
      case 1:
        return myWorkouts;
      case 2:
        // Get all possible workouts
        List<WorkoutPlan> allWorkouts = _getAllPossibleWorkouts();
        // Get current recommendations
        List<WorkoutPlan> recommendations =
            workout_logic.generateRecommendations(widget.user);

        // Filter out workouts that are already in recommendations
        return allWorkouts.where((workout) {
          return !recommendations.any((recommended) =>
              recommended.name == workout.name &&
              recommended.description == workout.description);
        }).toList();
      default:
        return [];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Already on this page
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/me');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<WorkoutPlan> currentWorkouts = _getCurrentWorkouts();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.orange),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Text(
              'Summary',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECOMMENDED WORKOUT',
                style: TextStyle(
                  color: Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTabButton('Recommended Workouts', 0),
                  const SizedBox(width: 16),
                  _buildTabButton('My Workouts', 1),
                  const SizedBox(width: 16),
                  _buildTabButton('Other Workouts', 2),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedTabIndex == 1 && myWorkouts.isEmpty
                    ? const Center(
                        child: Text(
                          'No Added Workouts Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                                    if (selectedTabIndex ==
                                        1) // Only show remove button in My Workouts
                                      TextButton(
                                        onPressed: () =>
                                            removeFromMyWorkouts(plan),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WorkoutDetailsPage(
                                              workout: plan,
                                              onAddToWorkoutList:
                                                  addToMyWorkouts,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'More',
                                        style: TextStyle(
                                          color:
                                              Color.fromRGBO(223, 77, 15, 1.0),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          selectedItemColor: const Color.fromRGBO(223, 77, 15, 1.0),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.fitness_center, 'Workouts', 1),
            _buildNavItem(Icons.history, 'History', 2),
            _buildNavItem(Icons.person, 'Me', 3),
          ],
        ),
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
      child: Text(
        text,
        style: TextStyle(
          color: isSelected
              ? const Color.fromRGBO(223, 77, 15, 1.0)
              : Colors.white70,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(_selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon,
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.white54),
      ),
      label: label,
    );
  }
}
