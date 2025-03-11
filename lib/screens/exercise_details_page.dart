import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Add this import for Timer
import '../models/workout_plan.dart';
import '../models/workout_history.dart';
import '../services/exercise_service.dart';
import '../services/workout_history_service.dart';

class ExerciseDetailsPage extends StatefulWidget {
  final Exercise exercise;
  final WorkoutPlan workout;

  const ExerciseDetailsPage({
    Key? key,
    required this.exercise,
    required this.workout,
  }) : super(key: key);

  @override
  State<ExerciseDetailsPage> createState() => _ExerciseDetailsPageState();
}

class _ExerciseDetailsPageState extends State<ExerciseDetailsPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutHistoryService _historyService = WorkoutHistoryService();
  Map<String, dynamic>? _exerciseDetails;
  bool _isLoading = true;
  int _completedSets = 0;
  bool _isCompleted = false;
  DateTime? _startTime;
  String? _currentHistoryId;
  final TextEditingController _notesController = TextEditingController();

  // Timer variables
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isResting = false;
  int _restTimeInSeconds = 0;

  @override
  void initState() {
    super.initState();
    _completedSets = widget.exercise.setsCompleted;
    _isCompleted = widget.exercise.isCompleted;
    _startTime = DateTime.now();
    _loadExerciseDetails();
    _parseRestTime();
  }

  void _parseRestTime() {
    // Parse rest time from format like "30s" or "1m"
    final restTime = widget.exercise.rest.toLowerCase();
    if (restTime.endsWith('s')) {
      _restTimeInSeconds =
          int.tryParse(restTime.substring(0, restTime.length - 1)) ?? 30;
    } else if (restTime.endsWith('m')) {
      _restTimeInSeconds =
          (int.tryParse(restTime.substring(0, restTime.length - 1)) ?? 1) * 60;
    } else {
      // If no unit is specified, assume seconds
      _restTimeInSeconds = int.tryParse(restTime) ?? 30;
    }
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _remainingSeconds = _restTimeInSeconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _stopRestTimer() {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      _remainingSeconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExerciseDetails() async {
    setState(() => _isLoading = true);
    final details =
        await _exerciseService.getExerciseDetails(widget.exercise.name);
    setState(() {
      _exerciseDetails = details;
      _isLoading = false;
    });
  }

  Future<void> _updateProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if the workout exists in My Workouts
        final workoutsCollection = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('name', isEqualTo: widget.workout.name)
            .get();

        if (workoutsCollection.docs.isEmpty) {
          // Show warning dialog if workout is not in My Workouts
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color.fromRGBO(44, 44, 46, 1.0),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          return; // Exit the method without saving any progress
        }

        // Check if there are any changes in the completed sets
        if (_completedSets == widget.exercise.setsCompleted) {
          // Show "Nothing Changed" message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nothing Changed'),
              backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
            ),
          );
          return;
        }

        // Only proceed with progress tracking if there are changes
        final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
        final duration = _startTime != null
            ? DateTime.now().difference(_startTime!).inSeconds
            : 0;

        // Update workout progress in Firestore
        final workoutDoc = workoutsCollection.docs.first;
        final exercises = workoutDoc.data()['exercises'] as List<dynamic>;
        final exerciseIndex =
            exercises.indexWhere((e) => e['name'] == widget.exercise.name);

        if (exerciseIndex != -1) {
          final isCompleted = _completedSets >= totalSets;

          exercises[exerciseIndex]['setsCompleted'] = _completedSets;
          exercises[exerciseIndex]['isCompleted'] = isCompleted;
          exercises[exerciseIndex]['lastCompleted'] =
              DateTime.now().toIso8601String();

          await workoutDoc.reference.update({'exercises': exercises});
        }

        // Update local exercise object
        final isCompleted = _completedSets >= totalSets;

        widget.exercise.setsCompleted = _completedSets;
        widget.exercise.isCompleted = isCompleted;
        widget.exercise.lastCompleted = DateTime.now();

        // Create history entry only if there is actual progress
        if (_completedSets > 0) {
          final history = WorkoutHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            workoutName: widget.workout.name,
            exerciseName: widget.exercise.name,
            date: DateTime.now(),
            setsCompleted: _completedSets,
            totalSets: totalSets,
            repsPerSet: int.tryParse(widget.exercise.reps) ?? 0,
            status: isCompleted ? 'completed' : 'in_progress',
            duration: duration,
            musclesWorked: widget.exercise.musclesWorked,
            notes: _notesController.text,
          );

          await _historyService.saveWorkoutHistory(history);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress Updated Successfully'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );

        // Navigate back to exercise list after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      print('Error updating progress: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating progress'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _watchVideo() {
    if (_exerciseDetails != null && _exerciseDetails!['gifUrl'] != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                _exerciseDetails!['gifUrl'],
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = int.tryParse(widget.exercise.sets) ?? 0;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                    // Exercise Image/GIF
                    if (_exerciseDetails != null &&
                        _exerciseDetails!['gifUrl'] != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(44, 44, 46, 1.0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _exerciseDetails!['gifUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Exercise Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(44, 44, 46, 1.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(223, 77, 15, 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.exercise.icon,
                                  color: const Color.fromRGBO(223, 77, 15, 1.0),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.exercise.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.exercise.sets} sets × ${widget.exercise.reps} reps | Rest: ${widget.exercise.rest}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Muscles Worked:',
                            style: TextStyle(
                              color: Color.fromRGBO(223, 77, 15, 1.0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.exercise.musclesWorked
                                .map((muscle) => Chip(
                                      label: Text(muscle),
                                      backgroundColor: const Color.fromRGBO(
                                          223, 77, 15, 0.2),
                                      labelStyle: const TextStyle(
                                        color: Color.fromRGBO(223, 77, 15, 1.0),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Instructions:',
                            style: TextStyle(
                              color: Color.fromRGBO(223, 77, 15, 1.0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _exerciseDetails?['instructions']?.join('\n\n') ??
                                'No instructions available.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Video Tutorial Button
                    if (_exerciseDetails != null &&
                        _exerciseDetails!['gifUrl'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _watchVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(223, 77, 15, 1.0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text(
                            'Watch Tutorial',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Progress Tracking Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(44, 44, 46, 1.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRACK YOUR PROGRESS',
                            style: TextStyle(
                              color: Color.fromRGBO(223, 77, 15, 1.0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Completed Sets: $_completedSets/$totalSets',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _completedSets > 0
                                        ? () {
                                            setState(() {
                                              _completedSets--;
                                              _isCompleted =
                                                  _completedSets >= totalSets;
                                            });
                                          }
                                        : null,
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    color: _completedSets > 0
                                        ? const Color.fromRGBO(223, 77, 15, 1.0)
                                        : Colors.grey,
                                  ),
                                  IconButton(
                                    onPressed: _completedSets < totalSets
                                        ? () {
                                            setState(() {
                                              _completedSets++;
                                              _isCompleted =
                                                  _completedSets >= totalSets;
                                            });
                                            // Start rest timer when a set is completed
                                            _startRestTimer();
                                          }
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _completedSets < totalSets
                                        ? const Color.fromRGBO(223, 77, 15, 1.0)
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value:
                                totalSets > 0 ? _completedSets / totalSets : 0,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isCompleted
                                  ? Colors.green
                                  : _completedSets > 0
                                      ? Colors.orange
                                      : const Color.fromRGBO(223, 77, 15, 1.0),
                            ),
                          ),
                          if (_isResting) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(223, 77, 15, 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rest Time',
                                        style: TextStyle(
                                          color:
                                              Color.fromRGBO(223, 77, 15, 1.0),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(_remainingSeconds),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: _stopRestTimer,
                                    icon: const Icon(
                                      Icons.stop_circle,
                                      color: Color.fromRGBO(223, 77, 15, 1.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add notes about your performance...',
                              hintStyle: TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(223, 77, 15, 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(223, 77, 15, 1.0),
                                ),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateProgress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(223, 77, 15, 1.0),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Update Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
