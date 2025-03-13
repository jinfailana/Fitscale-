import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Add this import for Timer
import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
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

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 60));
    _completedSets = widget.exercise.setsCompleted;
    _isCompleted = widget.exercise.isCompleted;
    _startTime = DateTime.now();
    _loadExerciseDetails();
    _parseRestTime();
  }

  void _parseRestTime() {
    // Parse rest time from format like "30s", "1m", "1:30", "90 seconds", "2 minutes"
    final restTime = widget.exercise.rest.toLowerCase().trim();

    // Try to parse different formats
    if (restTime.contains(':')) {
      // Format: "1:30" (minutes:seconds)
      final parts = restTime.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        _restTimeInSeconds = (minutes * 60) + seconds;
      }
    } else if (restTime.endsWith('s')) {
      // Format: "30s"
      _restTimeInSeconds =
          int.tryParse(restTime.substring(0, restTime.length - 1)) ?? 30;
    } else if (restTime.endsWith('m')) {
      // Format: "1m"
      _restTimeInSeconds =
          (int.tryParse(restTime.substring(0, restTime.length - 1)) ?? 1) * 60;
    } else if (restTime.contains('minute')) {
      // Format: "2 minutes" or "1 minute"
      final minutes = int.tryParse(restTime.split(' ')[0]) ?? 1;
      _restTimeInSeconds = minutes * 60;
    } else if (restTime.contains('second')) {
      // Format: "90 seconds" or "30 second"
      final seconds = int.tryParse(restTime.split(' ')[0]) ?? 30;
      _restTimeInSeconds = seconds;
    } else {
      // If no unit is specified, assume seconds
      _restTimeInSeconds = int.tryParse(restTime) ?? 30;
    }

    // Ensure minimum rest time of 5 seconds
    _restTimeInSeconds = _restTimeInSeconds.clamp(5, 300);
  }

  Future<bool> _onWillPop() async {
    if (_isResting) {
      // Show warning when trying to exit during rest
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the rest period'),
          backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Check if user has completed sets but hasn't updated progress
    if (_completedSets > widget.exercise.setsCompleted) {
      // Show warning dialog
      final shouldPop = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unsaved Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have completed sets that haven\'t been saved. Do you want to update your progress before leaving?',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(true); // Pop dialog and allow navigation
                        },
                        child: const Text(
                          'Leave Without Saving',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Get the workout document
                              final workoutDoc = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('workouts')
                                  .where('name', isEqualTo: widget.workout.name)
                                  .get()
                                  .then((snapshot) => snapshot.docs.first);

                              // Calculate progress values
                              final totalSets =
                                  int.tryParse(widget.exercise.sets) ?? 0;
                              final duration = _startTime != null
                                  ? DateTime.now()
                                      .difference(_startTime!)
                                      .inSeconds
                                  : 0;

                              // Update workout progress in Firestore
                              final exercises = workoutDoc.data()['exercises']
                                  as List<dynamic>;
                              final exerciseIndex = exercises.indexWhere(
                                  (e) => e['name'] == widget.exercise.name);

                              if (exerciseIndex != -1) {
                                exercises[exerciseIndex]['setsCompleted'] =
                                    _completedSets;
                                exercises[exerciseIndex]['lastCompleted'] =
                                    DateTime.now().toIso8601String();
                                await workoutDoc.reference
                                    .update({'exercises': exercises});
                              }

                              // Update local exercise object
                              widget.exercise.setsCompleted = _completedSets;
                              widget.exercise.lastCompleted = DateTime.now();

                              // Create history entry
                              final history = WorkoutHistory(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                workoutName: widget.workout.name,
                                exerciseName: widget.exercise.name,
                                date: DateTime.now(),
                                setsCompleted: _completedSets,
                                totalSets: totalSets,
                                repsPerSet:
                                    int.tryParse(widget.exercise.reps) ?? 0,
                                status: 'in_progress',
                                duration: duration,
                                musclesWorked: widget.exercise.musclesWorked,
                                notes: _notesController.text,
                              );

                              await _historyService.saveWorkoutHistory(history);

                              // Return to workout details
                              if (mounted) {
                                Navigator.of(context).pop(true);
                              }
                            }
                          } catch (e) {
                            print('Error updating progress: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error updating progress'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(223, 77, 15, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      return shouldPop ?? false;
    }

    return true;
  }

  void _startRestTimer() {
    if (_isResting) return; // Don't start if already resting

    final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
    final isFinalSet = _completedSets >= totalSets;

    setState(() {
      _isResting = true;
      _remainingSeconds = _restTimeInSeconds;
    });

    // Show appropriate message based on whether this is the final set
    if (isFinalSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Final set completed! Rest before finishing exercise.'),
          backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          duration: Duration(seconds: 2),
        ),
      );
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // Vibrate and play system sound when 3 seconds remaining
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            HapticFeedback.heavyImpact();
            SystemSound.play(SystemSoundType.click);
          }
        } else {
          _isResting = false;
          timer.cancel();

          // Check if all sets are completed after rest timer
          if (isFinalSet) {
            setState(() {
              _isCompleted = true;
            });

            // Play haptic feedback to indicate completion
            HapticFeedback.heavyImpact();
            Future.delayed(const Duration(milliseconds: 100), () {
              HapticFeedback.heavyImpact();
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              HapticFeedback.heavyImpact();
            });

            // Update progress and show completion dialog
            _updateProgressAndShowCompletion();
          } else {
            // If not all sets completed, just show rest complete message
            HapticFeedback.heavyImpact();
            Future.delayed(const Duration(milliseconds: 100), () {
              HapticFeedback.heavyImpact();
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              HapticFeedback.heavyImpact();
            });
            SystemSound.play(SystemSoundType.alert);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rest Complete! Continue your workout'),
                  backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
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
    _confettiController.stop();
    _confettiController.dispose();
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

  Widget _buildInstructions() {
    // First try to use the exercise's own instructions
    if (widget.exercise.instructions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.exercise.instructions.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ',
                  style: const TextStyle(
                    color: Color.fromRGBO(223, 77, 15, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Fall back to API instructions if available
    if (_exerciseDetails != null && _exerciseDetails!['instructions'] != null) {
      final instructions = _exerciseDetails!['instructions'];
      if (instructions is List) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: instructions.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ',
                    style: const TextStyle(
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      } else if (instructions is String) {
        return Text(
          instructions,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        );
      }
    }

    return const Text(
      'No instructions available.',
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Future<void> _updateProgressAndShowCompletion() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the workout document
        final workoutDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('name', isEqualTo: widget.workout.name)
            .get()
            .then((snapshot) => snapshot.docs.first);

        // Calculate progress values
        final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
        final duration = _startTime != null
            ? DateTime.now().difference(_startTime!).inSeconds
            : 0;
        final isCompleted = _completedSets >= totalSets;

        // Update workout progress in Firestore
        final exercises = workoutDoc.data()['exercises'] as List<dynamic>;
        final exerciseIndex =
            exercises.indexWhere((e) => e['name'] == widget.exercise.name);

        if (exerciseIndex != -1) {
          exercises[exerciseIndex]['setsCompleted'] = _completedSets;
          exercises[exerciseIndex]['isCompleted'] = isCompleted;
          exercises[exerciseIndex]['lastCompleted'] =
              DateTime.now().toIso8601String();
          await workoutDoc.reference.update({'exercises': exercises});
        }

        // Update local exercise object
        widget.exercise.setsCompleted = _completedSets;
        widget.exercise.isCompleted = isCompleted;
        widget.exercise.lastCompleted = DateTime.now();

        // Create history entry
        final history = WorkoutHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          workoutName: widget.workout.name,
          exerciseName: widget.exercise.name,
          date: DateTime.now(),
          setsCompleted: _completedSets,
          totalSets: totalSets,
          repsPerSet: int.tryParse(widget.exercise.reps) ?? 0,
          status: 'completed',
          duration: duration,
          musclesWorked: widget.exercise.musclesWorked,
          notes: _notesController.text,
        );

        await _historyService.saveWorkoutHistory(history);

        // Show completion dialog after successful update
        if (mounted) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      print('Error updating progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating progress'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _showCompletionDialog() {
    // Reset and play the confetti controller
    _confettiController.stop();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 60));
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Stack(
            children: [
              Dialog(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Exercise Completed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Great job! You\'ve completed all sets for this exercise.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _confettiController.stop();
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context)
                              .pop(); // Return to workout details
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(223, 77, 15, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  shouldLoop: true,
                  colors: const [
                    Colors.green,
                    Colors.amber,
                    Colors.orange,
                    Colors.red,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
    final bool isExerciseCompleted = widget.exercise.isCompleted;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Color.fromRGBO(223, 77, 15, 1.0)),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Text(
                widget.exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isExerciseCompleted) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
              ],
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
                                    color:
                                        const Color.fromRGBO(223, 77, 15, 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    widget.exercise.icon,
                                    color:
                                        const Color.fromRGBO(223, 77, 15, 1.0),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color:
                                              Color.fromRGBO(223, 77, 15, 1.0),
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
                            _buildInstructions(),
                            const SizedBox(height: 16),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Completed Sets: $_completedSets/$totalSets',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            ((_completedSets < totalSets &&
                                                        !_isResting) &&
                                                    !isExerciseCompleted)
                                                ? () {
                                                    setState(() {
                                                      _completedSets++;
                                                    });

                                                    // Start rest timer when a set is completed
                                                    _startRestTimer();

                                                    // The rest timer will handle showing messages and completion
                                                  }
                                                : null,
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        color: ((_completedSets < totalSets &&
                                                    !_isResting) &&
                                                !isExerciseCompleted)
                                            ? const Color.fromRGBO(
                                                223, 77, 15, 1.0)
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: totalSets > 0
                                        ? _completedSets / totalSets
                                        : 0,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isCompleted
                                          ? Colors.green
                                          : _completedSets > 0
                                              ? Colors.orange
                                              : const Color.fromRGBO(
                                                  223, 77, 15, 1.0),
                                    ),
                                  ),
                                  if (_isResting) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            223, 77, 15, 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color.fromRGBO(
                                              223, 77, 15, 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Rest Timer',
                                                    style: TextStyle(
                                                      color: Color.fromRGBO(
                                                          223, 77, 15, 1.0),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatTime(
                                                        _remainingSeconds),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: _remainingSeconds /
                                                _restTimeInSeconds,
                                            backgroundColor: Colors.grey[800],
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              Color.fromRGBO(223, 77, 15, 1.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (isExerciseCompleted) ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Exercise Completed!',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextField(
                                    controller: _notesController,
                                    enabled: !isExerciseCompleted,
                                    style: TextStyle(
                                      color: isExerciseCompleted
                                          ? Colors.grey
                                          : Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: isExerciseCompleted
                                          ? 'Exercise completed - Notes locked'
                                          : 'Add notes about your performance...',
                                      hintStyle: TextStyle(
                                        color: isExerciseCompleted
                                            ? Colors.grey
                                            : Colors.white54,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isExerciseCompleted
                                              ? Colors.grey
                                              : const Color.fromRGBO(
                                                  223, 77, 15, 0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isExerciseCompleted
                                              ? Colors.grey
                                              : const Color.fromRGBO(
                                                  223, 77, 15, 1.0),
                                        ),
                                      ),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (isExerciseCompleted ||
                                              _isResting)
                                          ? null
                                          : () async {
                                              // Check if there are any changes to save
                                              if (_completedSets ==
                                                  widget
                                                      .exercise.setsCompleted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'No changes to update. Complete some sets first!'),
                                                    backgroundColor:
                                                        Colors.grey,
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                                return;
                                              }

                                              // Check if any sets have been completed
                                              if (_completedSets == 0) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Complete at least one set before updating progress'),
                                                    backgroundColor:
                                                        Colors.grey,
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                                return;
                                              }

                                              // Check if all sets are completed
                                              final totalSets = int.tryParse(
                                                      widget.exercise.sets) ??
                                                  0;
                                              if (_completedSets >= totalSets) {
                                                // Start rest timer before completing
                                                if (!_isResting) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'All sets completed! Starting final rest period...'),
                                                      backgroundColor:
                                                          Color.fromRGBO(
                                                              223, 77, 15, 1.0),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ),
                                                  );
                                                  _startRestTimer();
                                                }
                                                return;
                                              }

                                              // If we get here, we're updating progress for a partially completed exercise
                                              try {
                                                final user = FirebaseAuth
                                                    .instance.currentUser;
                                                if (user != null) {
                                                  // Get the workout document
                                                  final workoutDoc =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(user.uid)
                                                          .collection(
                                                              'workouts')
                                                          .where('name',
                                                              isEqualTo: widget
                                                                  .workout.name)
                                                          .get()
                                                          .then((snapshot) =>
                                                              snapshot
                                                                  .docs.first);

                                                  // Calculate progress values
                                                  final totalSets =
                                                      int.tryParse(widget
                                                              .exercise.sets) ??
                                                          0;
                                                  final duration =
                                                      _startTime != null
                                                          ? DateTime.now()
                                                              .difference(
                                                                  _startTime!)
                                                              .inSeconds
                                                          : 0;

                                                  // Update workout progress in Firestore
                                                  final exercises = workoutDoc
                                                          .data()['exercises']
                                                      as List<dynamic>;
                                                  final exerciseIndex =
                                                      exercises.indexWhere(
                                                          (e) =>
                                                              e['name'] ==
                                                              widget.exercise
                                                                  .name);

                                                  if (exerciseIndex != -1) {
                                                    exercises[exerciseIndex]
                                                            ['setsCompleted'] =
                                                        _completedSets;
                                                    exercises[exerciseIndex]
                                                            ['lastCompleted'] =
                                                        DateTime.now()
                                                            .toIso8601String();
                                                    await workoutDoc.reference
                                                        .update({
                                                      'exercises': exercises
                                                    });
                                                  }

                                                  // Update local exercise object
                                                  widget.exercise
                                                          .setsCompleted =
                                                      _completedSets;
                                                  widget.exercise
                                                          .lastCompleted =
                                                      DateTime.now();

                                                  // Create history entry
                                                  final history =
                                                      WorkoutHistory(
                                                    id: DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString(),
                                                    workoutName:
                                                        widget.workout.name,
                                                    exerciseName:
                                                        widget.exercise.name,
                                                    date: DateTime.now(),
                                                    setsCompleted:
                                                        _completedSets,
                                                    totalSets: totalSets,
                                                    repsPerSet: int.tryParse(
                                                            widget.exercise
                                                                .reps) ??
                                                        0,
                                                    status: 'in_progress',
                                                    duration: duration,
                                                    musclesWorked: widget
                                                        .exercise.musclesWorked,
                                                    notes:
                                                        _notesController.text,
                                                  );

                                                  await _historyService
                                                      .saveWorkoutHistory(
                                                          history);

                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Progress updated successfully'),
                                                        backgroundColor:
                                                            Color.fromRGBO(223,
                                                                77, 15, 1.0),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                    Navigator.of(context)
                                                        .pop(); // Return to workout details after successful update
                                                  }
                                                }
                                              } catch (e) {
                                                print(
                                                    'Error updating progress: $e');
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Error updating progress'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (isExerciseCompleted || _isResting)
                                                ? Colors.grey
                                                : const Color.fromRGBO(
                                                    223, 77, 15, 1.0),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        isExerciseCompleted
                                            ? 'Exercise Completed'
                                            : _isResting
                                                ? 'Complete Rest Timer First'
                                                : 'Update Progress',
                                        style: const TextStyle(
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
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDF4D0F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<WorkoutHistory>>(
            future: _historyService.getWorkoutHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No workout data available',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              // Process the data for the graph
              final workouts = snapshot.data!;
              final completedWorkouts =
                  workouts.where((w) => w.status == 'completed').length;
              final totalWorkouts = workouts.length;
              final progress =
                  totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedWorkouts/$totalWorkouts Workouts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFFDF4D0F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFDF4D0F)),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        'Total Time',
                        '${workouts.fold<int>(0, (sum, w) => sum + w.duration)} min',
                      ),
                      _buildStatCard(
                        'Sets Done',
                        '${workouts.fold<int>(0, (sum, w) => sum + w.setsCompleted)}',
                      ),
                      _buildStatCard(
                        'Exercises',
                        '${workouts.length}',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}