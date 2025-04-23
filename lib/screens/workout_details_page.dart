import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import 'exercise_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final WorkoutPlan workout;
  final Function(WorkoutPlan) onAddToWorkoutList;
  final bool isFromMyWorkouts;

  const WorkoutDetailsPage({
    super.key,
    required this.workout,
    required this.onAddToWorkoutList,
    this.isFromMyWorkouts = false,
  });

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late WorkoutPlan _workout;
  bool _isLoading = true;
  bool _isInMyWorkouts = false;
  bool _isAddingWorkout = false;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    print(
        'Initial workout: ${_workout.name}, Exercises: ${_workout.exercises.length}');
    _loadWorkoutProgress();
  }

  Future<void> _loadWorkoutProgress() async {
    print('Starting to load workout progress...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, showing initial state');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Get the workout document
      final workoutDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(_workout.name)
          .get();

      if (!workoutDoc.exists) {
        print('No workout document found, showing initial state');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInMyWorkouts = false;
          });
        }
        return;
      }

      final workoutData = workoutDoc.data();
      if (workoutData == null) {
        print('Workout document exists but has no data');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInMyWorkouts = false;
          });
        }
        return;
      }

      // Check if workout is in user's list
      _isInMyWorkouts = true;

      // Get exercises data
      final exercisesData = workoutData['exercises'] as Map<String, dynamic>?;
      if (exercisesData == null) {
        print('No exercises found in workout data');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Update each exercise in the workout with saved progress
      for (var exercise in _workout.exercises) {
        final exerciseData =
            exercisesData[exercise.name] as Map<String, dynamic>?;
        if (exerciseData != null) {
          exercise.setsCompleted = exerciseData['setsCompleted'] as int? ?? 0;
          exercise.isCompleted = exerciseData['isCompleted'] as bool? ?? false;
          if (exerciseData['lastCompleted'] != null) {
            try {
              exercise.lastCompleted =
                  DateTime.parse(exerciseData['lastCompleted'] as String);
            } catch (e) {
              print('Error parsing lastCompleted date: $e');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading workout progress: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getExerciseBorderColor(Exercise exercise) {
    if (exercise.isCompleted) {
      return Colors.green;
    } else if (exercise.setsCompleted > 0) {
      return Colors.orange;
    }
    return const Color.fromRGBO(223, 77, 15, 1.0);
  }

  bool _isWorkoutCompleted() {
    return _workout.exercises.every((exercise) => exercise.isCompleted);
  }

  Future<void> _addWorkout() async {
    if (_isAddingWorkout) return;

    setState(() {
      _isAddingWorkout = true;
    });

    try {
      await widget.onAddToWorkoutList(_workout);
      setState(() {
        _isInMyWorkouts = true;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add workout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingWorkout = false;
        });
      }
    }
  }

  void _navigateToExercise(Exercise exercise) async {
    if (exercise.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise already completed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailsPage(
          exercise: exercise,
          workout: _workout,
        ),
      ),
    );

    // Refresh the workout progress when returning from exercise details
    _loadWorkoutProgress();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllExercisesCompleted = _isWorkoutCompleted();
    print(
        'Building workout details page. Exercises count: ${_workout.exercises.length}');

    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              _workout.icon,
              color: const Color.fromRGBO(223, 77, 15, 1.0),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _workout.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkoutProgress,
              child: _workout.exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises found in this workout',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_workout.isInProgress ||
                                isAllExercisesCompleted)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isAllExercisesCompleted
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isAllExercisesCompleted
                                          ? Icons.check_circle
                                          : Icons.timer,
                                      color: isAllExercisesCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAllExercisesCompleted
                                          ? 'Workout Completed!'
                                          : 'Workout in Progress',
                                      style: TextStyle(
                                        color: isAllExercisesCompleted
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'WORKOUT DESCRIPTION:',
                                    style: TextStyle(
                                      color: Color.fromRGBO(223, 77, 15, 1.0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _workout.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'EXERCISES:',
                                    style: TextStyle(
                                      color: Color.fromRGBO(223, 77, 15, 1.0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._workout.exercises.map((exercise) =>
                                      GestureDetector(
                                        onTap: (!widget.isFromMyWorkouts &&
                                                !_isInMyWorkouts)
                                            ? () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Add workout to your list to access exercises'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            : exercise.isCompleted
                                                ? () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Exercise already completed!'),
                                                        backgroundColor:
                                                            Colors.green,
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                : () async {
                                                    if (_isAddingWorkout) {
                                                      return;
                                                    }
                                                    _navigateToExercise(
                                                        exercise);
                                                  },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                                44, 44, 46, 1.0),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isAllExercisesCompleted
                                                  ? Colors.green
                                                  : _getExerciseBorderColor(
                                                      exercise),
                                              width: 2,
                                            ),
                                            gradient: (!widget
                                                        .isFromMyWorkouts &&
                                                    !_isInMyWorkouts)
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color.fromRGBO(
                                                          44, 44, 46, 0.7),
                                                      Color.fromRGBO(
                                                          44, 44, 46, 0.7),
                                                    ],
                                                  )
                                                : exercise.isCompleted
                                                    ? LinearGradient(
                                                        colors: [
                                                          Colors.green
                                                              .withOpacity(0.1),
                                                          Colors.green
                                                              .withOpacity(0.1),
                                                        ],
                                                      )
                                                    : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      223, 77, 15, 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  exercise.icon,
                                                  color: const Color.fromRGBO(
                                                      223, 77, 15, 1.0),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          exercise.name,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        if (exercise
                                                            .isCompleted) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 20,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${exercise.sets} sets × ${exercise.reps} | Rest: ${exercise.rest}',
                                                      style: TextStyle(
                                                        color: exercise
                                                                .isCompleted
                                                            ? Colors.grey
                                                            : Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (exercise.setsCompleted >
                                                        0) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        exercise.isCompleted
                                                            ? 'Completed!'
                                                            : 'Progress: ${exercise.setsCompleted}/${exercise.sets} sets',
                                                        style: TextStyle(
                                                          color: exercise
                                                                  .isCompleted
                                                              ? Colors.green
                                                              : Colors.orange,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                    if (exercise.musclesWorked
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Wrap(
                                                        spacing: 4,
                                                        children: exercise
                                                            .musclesWorked
                                                            .map(
                                                                (muscle) =>
                                                                    Text(
                                                                      muscle,
                                                                      style:
                                                                          const TextStyle(
                                                                        color: Color.fromRGBO(
                                                                            223,
                                                                            77,
                                                                            15,
                                                                            1.0),
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ))
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (!widget.isFromMyWorkouts && !_isInMyWorkouts)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isAddingWorkout ? null : _addWorkout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(223, 77, 15, 1.0),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isAddingWorkout
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Add to Workout List',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
}
