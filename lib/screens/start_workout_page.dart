import 'package:flutter/material.dart';
import 'workout_tracker_page.dart';
import 'workout_history_page.dart';

class StartWorkoutPage extends StatefulWidget {
  const StartWorkoutPage({Key? key}) : super(key: key);

  @override
  State<StartWorkoutPage> createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  String _selectedWorkoutType = 'Running';
  String? _selectedGoal;
  
  final List<String> _workoutTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Hiking',
    'Swimming',
    'Strength Training',
  ];
  
  final Map<String, List<String>> _workoutGoals = {
    'Running': [
      'Complete 5K',
      'Improve pace',
      'Build endurance',
      'Weight loss',
      'Just for fun',
    ],
    'Walking': [
      'Daily steps',
      'Weight loss',
      'Active recovery',
      'Explore area',
      'Just for fun',
    ],
    'Cycling': [
      'Complete 10K',
      'Hill training',
      'Weight loss',
      'Improve speed',
      'Just for fun',
    ],
    'Hiking': [
      'Summit a peak',
      'Explore new trail',
      'Nature photography',
      'Geocaching',
      'Just for fun',
    ],
    'Swimming': [
      'Complete 1K',
      'Technique practice',
      'Open water swim',
      'Recovery workout',
      'Just for fun',
    ],
    'Strength Training': [
      'Build muscle',
      'Increase strength',
      'Tone muscles',
      'Recovery workout',
      'Just for fun',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Workout'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Workout History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Type Section
                const Text(
                  'Select Workout Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _workoutTypes.length,
                    itemBuilder: (context, index) {
                      final workoutType = _workoutTypes[index];
                      final isSelected = workoutType == _selectedWorkoutType;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkoutType = workoutType;
                            _selectedGoal = null; // Reset goal when type changes
                          });
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.blue[400] 
                                : Colors.blue[800]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getWorkoutIcon(workoutType),
                                color: Colors.white,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                workoutType,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Workout Goal Section
                const Text(
                  'Select Goal (Optional)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _workoutGoals[_selectedWorkoutType]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final goal = _workoutGoals[_selectedWorkoutType]![index];
                      final isSelected = goal == _selectedGoal;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGoal = goal;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.blue[400] 
                                : Colors.blue[800]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                goal,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'START WORKOUT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
  
  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTrackerPage(
          workoutType: _selectedWorkoutType,
          workoutGoal: _selectedGoal,
        ),
      ),
    ).then((value) {
      // Refresh if returned with completion flag
      if (value == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout completed successfully!')),
        );
      }
    });
  }
  
  IconData _getWorkoutIcon(String workoutType) {
    switch (workoutType) {
      case 'Running':
        return Icons.directions_run;
      case 'Walking':
        return Icons.directions_walk;
      case 'Cycling':
        return Icons.directions_bike;
      case 'Hiking':
        return Icons.terrain;
      case 'Swimming':
        return Icons.pool;
      case 'Strength Training':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }
} 