// lib/screens/recommendations_page.dart
import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../models/user_model.dart';

class RecommendationsPage extends StatefulWidget {
  final UserModel user;

  const RecommendationsPage({super.key, required this.user});

  @override
  _RecommendationsPageState createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  int selectedTabIndex = 0;
  int _selectedIndex = 1;

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
    List<WorkoutPlan> recommendations = generateRecommendations(widget.user);

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
                child: ListView.builder(
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final plan = recommendations[index];
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
                              // Placeholder for image
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle "More" button press
                              },
                              child: const Text(
                                'More',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
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

  List<WorkoutPlan> generateRecommendations(UserModel user) {
    List<WorkoutPlan> recommendations = [];

    // Goal-based recommendations (from set_goal.dart)
    switch (user.goal?.toLowerCase() ?? '') {
      case "lose weight":
        recommendations.add(WorkoutPlan(
          name: "Fat Burning Program",
          description:
              "High-intensity cardio and metabolic workouts for maximum calorie burn.",
        ));
        recommendations.add(WorkoutPlan(
          name: "Weight Loss Circuit",
          description:
              "Combined cardio and strength training to promote fat loss.",
        ));
        break;
      case "build muscle":
        recommendations.add(WorkoutPlan(
          name: "Muscle Building Program",
          description:
              "Progressive overload training with focus on hypertrophy.",
        ));
        recommendations.add(WorkoutPlan(
          name: "Strength Foundation",
          description:
              "Compound exercises for muscle growth and strength gains.",
        ));
        break;
      case "stay fit":
        recommendations.add(WorkoutPlan(
          name: "Balanced Fitness",
          description:
              "Well-rounded workouts combining cardio, strength, and flexibility.",
        ));
        recommendations.add(WorkoutPlan(
          name: "Maintenance Program",
          description: "Balanced routines to maintain current fitness level.",
        ));
        break;
    }

    // Preferred workout level recommendations (from pref_workout.dart)
    if (user.preferredWorkouts?.isNotEmpty == true) {
      String workoutLevel = user.preferredWorkouts!.first.toLowerCase();
      switch (workoutLevel) {
        case "beginner":
          recommendations.add(WorkoutPlan(
            name: "Beginner Fundamentals",
            description:
                "Best for newbies or just starting - Foundation exercises with proper form.",
          ));
          break;
        case "intermediate":
          recommendations.add(WorkoutPlan(
            name: "Intermediate Progress",
            description:
                "For those with some experience - Progressive workouts with advanced variations.",
          ));
          break;
        case "advanced":
          recommendations.add(WorkoutPlan(
            name: "Advanced Training",
            description:
                "For experienced individuals - Complex routines for peak performance.",
          ));
          break;
        case "expert":
          recommendations.add(WorkoutPlan(
            name: "Expert Level",
            description:
                "For top-level athletes - Professional-grade training programs.",
          ));
          break;
      }
    }

    // Activity level recommendations (from act_level.dart)
    switch (user.activityLevel?.toLowerCase() ?? '') {
      case "sedentary":
        recommendations.add(WorkoutPlan(
          name: "Beginner's Movement",
          description:
              "Little to no exercise - Light exercises to build basic fitness foundation.",
        ));
        break;
      case "lightly active":
        recommendations.add(WorkoutPlan(
          name: "Active Lifestyle",
          description:
              "Light exercise 1-3 days/week - Moderate intensity workouts.",
        ));
        break;
      case "moderately active":
        recommendations.add(WorkoutPlan(
          name: "Progressive Fitness",
          description:
              "Moderate exercise 3-5 days/week - Structured progression plan.",
        ));
        break;
      case "very active":
        recommendations.add(WorkoutPlan(
          name: "High Performance",
          description:
              "Hard exercise 6-7 days/week - Intense training program.",
        ));
        break;
      case "extremely active":
        recommendations.add(WorkoutPlan(
          name: "Elite Training",
          description:
              "Very hard exercise & physical job - Peak performance program.",
        ));
        break;
    }

    // Workout place recommendations (from work_place.dart)
    switch (user.workoutPlace?.toLowerCase() ?? '') {
      case "home":
        recommendations.add(WorkoutPlan(
          name: "Home Warrior",
          description: "Effective workouts optimized for home environment.",
        ));
        break;
      case "gym":
        recommendations.add(WorkoutPlan(
          name: "Gym Performance",
          description: "Structured workouts utilizing full gym equipment.",
        ));
        break;
      case "outdoor":
        recommendations.add(WorkoutPlan(
          name: "Outdoor Athletics",
          description: "Dynamic workouts leveraging outdoor environments.",
        ));
        break;
      case "mixed":
        recommendations.add(WorkoutPlan(
          name: "Hybrid Training",
          description:
              "Versatile workouts combining home, gym, and outdoor exercises.",
        ));
        break;
    }

    // Equipment availability (from gym_equipment.dart)
    if (user.gymEquipment?.isNotEmpty == true) {
      String equipment = user.gymEquipment!.first.toLowerCase();
      if (equipment.contains("bodyweight")) {
        recommendations.add(WorkoutPlan(
          name: "Bodyweight Mastery",
          description:
              "Complete program using only bodyweight exercises - no equipment needed.",
        ));
      } else if (equipment.contains("gym")) {
        recommendations.add(WorkoutPlan(
          name: "Full Equipment Program",
          description:
              "Comprehensive workouts utilizing available gym equipment.",
        ));
      }
    }

    // Gender-specific recommendations (from select_gender.dart)
    if (user.gender?.toLowerCase() == "female") {
      recommendations.add(WorkoutPlan(
        name: "Women's Fitness",
        description:
            "Customized workouts that can be adapted to any equipment level.",
      ));
    }

    return recommendations;
  }
}
