import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import 'exercise_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final WorkoutPlan workout;
  final Function(WorkoutPlan) onAddToWorkoutList;

  const WorkoutDetailsPage({
    Key? key,
    required this.workout,
    required this.onAddToWorkoutList,
  }) : super(key: key);

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late WorkoutPlan _workout;
  bool _isLoading = true;
  bool _isInMyWorkouts = false;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _loadWorkoutProgress();
  }

  Future<void> _loadWorkoutProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final workoutDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('name', isEqualTo: widget.workout.name)
            .get();

        if (workoutDoc.docs.isNotEmpty) {
          final data = workoutDoc.docs.first.data();
          final updatedWorkout = WorkoutPlan.fromMap(data);

          // Update the exercises in the current workout with the saved progress
          for (var i = 0; i < updatedWorkout.exercises.length; i++) {
            if (i < widget.workout.exercises.length) {
              widget.workout.exercises[i].setsCompleted =
                  updatedWorkout.exercises[i].setsCompleted;
              widget.workout.exercises[i].isCompleted =
                  updatedWorkout.exercises[i].isCompleted;
              widget.workout.exercises[i].lastCompleted =
                  updatedWorkout.exercises[i].lastCompleted;
            }
          }

          setState(() {
            _workout = widget.workout;
            _isLoading = false;
            _isInMyWorkouts = true;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading workout progress: $e');
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final bool isAllExercisesCompleted = _isWorkoutCompleted();
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_workout.isInProgress)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: isAllExercisesCompleted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                isAllExercisesCompleted
                                    ? Icons.check_circle
                                    : Icons.timer,
                                color: isAllExercisesCompleted
                                    ? Colors.green
                                    : Colors.orange),
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
                            if (isAllExercisesCompleted) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          ..._workout.exercises
                              .map((exercise) => GestureDetector(
                                    onTap: () async {
                                      if (!_isInMyWorkouts) {
                                        // Show warning dialog if workout is not in My Workouts
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor:
                                                  const Color.fromRGBO(
                                                      44, 44, 46, 1.0),
                                              title: const Text(
                                                'Workout Not Added',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: const Text(
                                                'You need to add this workout to My Workouts before performing exercises.',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text(
                                                    'OK',
                                                    style: TextStyle(
                                                      color: Color.fromRGBO(
                                                          223, 77, 15, 1.0),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        return;
                                      }
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ExerciseDetailsPage(
                                            exercise: exercise,
                                            workout: _workout,
                                          ),
                                        ),
                                      );
                                      _loadWorkoutProgress(); // Reload progress after returning
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            44, 44, 46, 1.0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isAllExercisesCompleted
                                              ? Colors.green
                                              : _getExerciseBorderColor(
                                                  exercise),
                                          width: 2,
                                        ),
                                        // Add opacity to indicate non-clickable state
                                        gradient: !_isInMyWorkouts
                                            ? LinearGradient(
                                                colors: [
                                                  const Color.fromRGBO(
                                                      44, 44, 46, 0.7),
                                                  const Color.fromRGBO(
                                                      44, 44, 46, 0.7),
                                                ],
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
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
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (exercise
                                                        .isCompleted) ...[
                                                      const SizedBox(width: 8),
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
                                                    color: exercise.isCompleted
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
                                                      color:
                                                          exercise.isCompleted
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
                                                        .map((muscle) => Text(
                                                              muscle,
                                                              style:
                                                                  const TextStyle(
                                                                color: Color
                                                                    .fromRGBO(
                                                                        223,
                                                                        77,
                                                                        15,
                                                                        1.0),
                                                                fontSize: 12,
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
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_isInMyWorkouts)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAddToWorkoutList(_workout);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to My Workouts'),
                                backgroundColor:
                                    Color.fromRGBO(223, 77, 15, 1.0),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(223, 77, 15, 1.0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
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
    );
  }
}
