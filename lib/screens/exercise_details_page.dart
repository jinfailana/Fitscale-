import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import '../models/workout_plan.dart';
import '../models/workout_history.dart';
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

class _ExerciseDetailsPageState extends State<ExerciseDetailsPage>
    with WidgetsBindingObserver {
  late final WorkoutHistoryService _historyService;
  bool _isLoading = true;
  late int _completedSets;
  bool _isCompleted = false;
  DateTime? _startTime;
  final TextEditingController _notesController = TextEditingController();

  // Timer variables
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isResting = false;
  int _restTimeInSeconds = 0;

  late ConfettiController _confettiController;
  bool _hasUnsavedChanges = false;
  bool _isLastSet = false;
  bool _showingCompletionDialog = false;
  bool _canUpdateProgress = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _historyService = WorkoutHistoryService(userId: user.uid);
    }
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _completedSets = widget.exercise.setsCompleted;
    _loadExerciseProgress();
    _startTime = DateTime.now();
    _parseRestTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _timer?.cancel();
    _notesController.dispose();
    if (_hasUnsavedChanges) {
      _handleProgressUpdate(shouldNavigateBack: false);
    }
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused && _hasUnsavedChanges) {
      await _handleProgressUpdate();
    }
  }

  void _parseRestTime() {
    try {
      final restTime = widget.exercise.rest.toLowerCase().trim();

      // Handle complex formats like "1 minute sprint, 2 minute walk"
      if (restTime.contains(',')) {
        // Take the first part before the comma for rest time
        final firstPart = restTime.split(',')[0].trim();
        _parseSimpleRestTime(firstPart);
        return;
      }

      _parseSimpleRestTime(restTime);
    } catch (e) {
      print('Error parsing rest time: $e');
      // Default to 30 seconds if parsing fails
      _restTimeInSeconds = 30;
    }
  }

  void _parseSimpleRestTime(String restTime) {
    if (restTime.contains(':')) {
      final parts = restTime.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        _restTimeInSeconds = (minutes * 60) + seconds;
      }
    } else if (restTime.endsWith('s')) {
      final seconds =
          int.tryParse(restTime.substring(0, restTime.length - 1).trim()) ?? 30;
      _restTimeInSeconds = seconds;
    } else if (restTime.endsWith('m')) {
      final minutes =
          int.tryParse(restTime.substring(0, restTime.length - 1).trim()) ?? 1;
      _restTimeInSeconds = minutes * 60;
    } else if (restTime.contains('minute')) {
      // Extract number before "minute"
      final match = RegExp(r'(\d+)').firstMatch(restTime);
      final minutes = int.tryParse(match?.group(1) ?? '') ?? 1;
      _restTimeInSeconds = minutes * 60;
    } else if (restTime.contains('second')) {
      // Extract number before "second"
      final match = RegExp(r'(\d+)').firstMatch(restTime);
      final seconds = int.tryParse(match?.group(1) ?? '') ?? 30;
      _restTimeInSeconds = seconds;
    } else {
      // Try parsing as direct seconds
      _restTimeInSeconds = int.tryParse(restTime) ?? 30;
    }

    // Ensure rest time is within reasonable bounds
    _restTimeInSeconds = _restTimeInSeconds.clamp(5, 300);
  }

  Future<void> _loadExerciseProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final workoutDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(widget.workout.name)
          .get();

      if (!workoutDoc.exists || workoutDoc.data() == null) return;

      final workoutData = workoutDoc.data()!;

      // Safely handle exercises data
      if (workoutData['exercises'] is! List) {
        print('Invalid exercises data format');
        return;
      }

      final exercises = (workoutData['exercises'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final exerciseData = exercises.firstWhere(
        (e) => e['name'] == widget.exercise.name,
        orElse: () => <String, dynamic>{},
      );

      if (exerciseData.isNotEmpty) {
        setState(() {
          _completedSets = exerciseData['setsCompleted'] ?? 0;
          _hasUnsavedChanges = false;
          widget.exercise.setsCompleted = _completedSets;
          widget.exercise.isCompleted = exerciseData['isCompleted'] ?? false;
          if (exerciseData['lastCompleted'] != null) {
            widget.exercise.lastCompleted =
                DateTime.parse(exerciseData['lastCompleted']);
          }
        });
      }
    } catch (e) {
      print('Error loading exercise progress: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playRestCompleteSound() async {
    try {
      // Vibrate with pattern for better feedback
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();

      // Play system notification sound
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Error playing sound feedback: $e');
    }
  }

  void _startRestTimer() {
    if (_isResting) return;

    final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
    final isFinalSet = _completedSets >= totalSets - 1;
    _isLastSet = isFinalSet;

    setState(() {
      _isResting = true;
      _remainingSeconds = _restTimeInSeconds;
      _canUpdateProgress = false;
      if (!isFinalSet) {
        _completedSets++;
        _hasUnsavedChanges = true;
      }
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            HapticFeedback.mediumImpact();
          }
        } else {
          _isResting = false;
          timer.cancel();
          _canUpdateProgress = true;

          if (_isLastSet && !_showingCompletionDialog) {
            _showingCompletionDialog = true;
            _playRestCompleteSound();
            _showCompletionDialog();
          } else {
            _playRestCompleteSound();
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleProgressUpdate({bool shouldNavigateBack = true}) async {
    if (_completedSets == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete at least one set before saving progress'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isResting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the rest timer to complete'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final totalSets = int.tryParse(widget.exercise.sets) ?? 0;
      final isCompleted = _completedSets >= totalSets;

      // First try to update exercise progress
      await _historyService.updateExerciseProgress(
        widget.workout.name,
        widget.exercise.name,
        _completedSets,
        isCompleted,
      );

      // Then try to log the exercise
      try {
        await _historyService.logExercise(
          widget.workout,
          widget.exercise,
          _completedSets,
          _notesController.text,
        );
      } catch (logError) {
        print('Error logging exercise: $logError');
        // Show warning but don't fail the whole operation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Progress saved but there was an error logging the exercise'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      setState(() {
        _hasUnsavedChanges = false;
        widget.exercise.setsCompleted = _completedSets;
        widget.exercise.isCompleted = isCompleted;
        widget.exercise.lastCompleted = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );

        if (shouldNavigateBack) {
          Navigator.of(context).pop(); // Return to workout page
        }
      }
    } catch (e) {
      print('Error saving progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleLeaveWithoutSaving() async {
    setState(() {
      _completedSets = 0;
      _hasUnsavedChanges = false;
      widget.exercise.setsCompleted = 0;
      widget.exercise.isCompleted = false;
      widget.exercise.lastCompleted = null;
    });
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isResting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the rest timer to complete'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    if (!_hasUnsavedChanges || _completedSets == 0) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color.fromRGBO(44, 44, 46, 1.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Unsaved Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              const Text(
                'You have unsaved progress.\nWould you like to save before exiting?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Leave Without Saving Button
                  Expanded(
                    child: TextButton(
                      onPressed: _handleLeaveWithoutSaving,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Update Progress Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _handleProgressUpdate();
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

    return result ?? false;
  }

  Future<void> _showCompletionDialog() async {
    final totalSets = int.tryParse(widget.exercise.sets) ?? 0;

    _confettiController.play();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            AlertDialog(
              backgroundColor: const Color.fromRGBO(44, 44, 46, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              contentPadding: const EdgeInsets.all(24),
              title: const Center(
                child: Column(
                  children: [
                    Text(
                      '🎉',
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Congratulations!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You\'ve completed all sets for this exercise!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${widget.exercise.sets} sets × ${widget.exercise.reps}',
                    style: const TextStyle(
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isCompleted = true;
                        _completedSets = totalSets;
                        _hasUnsavedChanges = true;
                      });

                      await _handleProgressUpdate(shouldNavigateBack: false);

                      if (mounted) {
                        Navigator.of(context)
                            .pop(); // Pop the completion dialog
                        Navigator.of(context)
                            .pop(); // Pop the exercise details page
                      }
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 1,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                colors: const [
                  Colors.orange,
                  Colors.red,
                  Colors.yellow,
                  Colors.blue,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        appBar: AppBar(
          title: Text(widget.exercise.name),
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          elevation: 0,
          leading: _isResting
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (await _onWillPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildExerciseImage(),
                ),
                const SizedBox(height: 24),

                // Exercise Info
                Container(
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
                          Text(
                            widget.exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.exercise.sets} sets × ${widget.exercise.reps} | Rest: ${widget.exercise.rest}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Muscles Worked
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
                  children: widget.exercise.musclesWorked.map((muscle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(44, 44, 46, 1.0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color.fromRGBO(223, 77, 15, 0.3),
                        ),
                      ),
                      child: Text(
                        muscle,
                        style: const TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Instructions
                const Text(
                  'Instructions:',
                  style: TextStyle(
                    color: Color.fromRGBO(223, 77, 15, 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.exercise.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: const TextStyle(
                              color: Color.fromRGBO(223, 77, 15, 1.0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
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
                ),
                const SizedBox(height: 24),

                // Track Progress Section
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
                      'Completed Sets: $_completedSets/${widget.exercise.sets}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isResting && !_isCompleted)
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: (_completedSets > 0 &&
                                    _canUpdateProgress &&
                                    !_isResting)
                                ? () => _handleProgressUpdate()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_completedSets > 0 &&
                                      _canUpdateProgress &&
                                      !_isResting)
                                  ? const Color.fromRGBO(223, 77, 15, 1.0)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Update Progress'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: !_isResting ? _startRestTimer : null,
                            icon: Icon(
                              Icons.add_circle,
                              color: !_isResting
                                  ? const Color.fromRGBO(223, 77, 15, 1.0)
                                  : Colors.grey,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rest Timer
                if (_isResting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(44, 44, 46, 1.0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(223, 77, 15, 1.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'REST TIME',
                          style: TextStyle(
                            color: Color.fromRGBO(223, 77, 15, 1.0),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                // Notes Section
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white70),
                  decoration: const InputDecoration(
                    hintText: 'Add notes about your performance...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                      ),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseImage() {
    if (widget.exercise.imageHtml.isNotEmpty) {
      final RegExp regExp = RegExp(r'src="([^"]+)"');
      final match = regExp.firstMatch(widget.exercise.imageHtml);
      final imageUrl = match?.group(1) ?? '';

      if (imageUrl.isEmpty) {
        return _buildNoImagePlaceholder();
      }

      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: const Color.fromRGBO(44, 44, 46, 1.0),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildNoImagePlaceholder();
        },
      );
    }
    return _buildNoImagePlaceholder();
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(44, 44, 46, 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_gymnastics,
            color: Color.fromRGBO(223, 77, 15, 1.0),
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
