import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' show pi, cos, sin;
import '../widgets/goal_selection_sheet.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';  
import 'package:http/http.dart' as http;
import '../services/step_goal_service.dart';


class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> with WidgetsBindingObserver {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  // Pedometer streams
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Step tracking variables
  int _steps = 0;
  double _percentage = 0;
  int _calories = 0;
  double _distance = 0;
  String _status = 'unknown';
  bool _hasSetGoal = false;
  int _goal = 0;
  DateTime? _lastGoalSetDate;

  final StepGoalService _stepGoalService = StepGoalService();

  int _initialSteps = 0;
  bool _isFirstReading = true;

  // Add to class variables
  bool _goalCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;
        await _initializeUserData();
        await _requestPermissions();
        await _initializePedometer();
      }
    } catch (e) {
      print('Error initializing tracking: $e');
      _showError('Failed to initialize tracking');
    }
  }

  Future<void> _initializeUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;
        
        // Get the last saved steps for today
        final userDoc = await _firestore.collection('users').doc(_userId).get();
        final data = userDoc.data();
        
        if (data != null) {
          final lastUpdateDate = data['date'] as Timestamp?;
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          
          // If last update was today, use those steps
          if (lastUpdateDate != null && 
              _isSameDay(lastUpdateDate.toDate(), todayDate)) {
            setState(() {
              _steps = data['current_steps'] ?? 0;
              _calories = data['calories'] ?? 0;
              _distance = (data['distance'] ?? 0).toDouble();
            });
          } else {
            // If it's a new day, start from 0
            await _firestore.collection('users').doc(_userId).set({
              'current_steps': 0,
              'calories': 0,
              'distance': 0,
              'last_updated': FieldValue.serverTimestamp(),
              'date': Timestamp.fromDate(todayDate),
            }, SetOptions(merge: true));
          }
        }
        
        await _checkExistingGoal();
      }
    } catch (e) {
      print('Error initializing user data: $e');
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _checkExistingGoal() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['step_goal'] != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Get the last goal set date
          DateTime? goalSetDate;
          if (data?['goal_set_date'] != null) {
            goalSetDate = (data?['goal_set_date'] as Timestamp).toDate();
          }
          
          // Check if goal was set on a different day
          if (goalSetDate != null && !_isSameDay(goalSetDate, today)) {
            // Goal is from a previous day, reset it
            await _resetGoal();
          } else {
            // Goal is from today, use it
            setState(() {
              _hasSetGoal = true;
              _goal = data?['step_goal'];
              _lastGoalSetDate = goalSetDate;
            });
          }
        }
      }
    } catch (e) {
      print('Error checking goal: $e');
    }
  }

  // New method to reset the goal
  Future<void> _resetGoal() async {
    try {
      setState(() {
        _hasSetGoal = false;
        _goal = 0;
        _percentage = 0;
        _goalCompleted = false;
      });
      
      await _firestore.collection('users').doc(_userId).update({
        'step_goal': null,
        'goal_set_date': null,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily step goal has been reset. Set a new goal for today!'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );
      }
    } catch (e) {
      print('Error resetting goal: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) allGranted = false;
    });

    if (!allGranted) {
      if (!mounted) return;
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs activity recognition and sensor permissions to count your steps.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }
  }

  Future<void> _initializePedometer() async {
    try {
      _stepCountSubscription?.cancel();
      _pedestrianStatusSubscription?.cancel();
      
      // Reset step counting variables
      _isFirstReading = true;
      _initialSteps = 0;
      _steps = 0;

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        onStepCount,
        onError: (error) => _handleSensorError('Step counter', error),
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        onPedestrianStatusChanged,
        onError: (error) => _handleSensorError('Activity detection', error),
        cancelOnError: false,
      );
    } catch (e) {
      print('Error initializing pedometer: $e');
      _handleSensorError('Pedometer', e);
    }
  }

  void onStepCount(StepCount event) async {
    if (_isFirstReading) {
      _initialSteps = event.steps;
      _isFirstReading = false;
    }

    setState(() {
      // Calculate actual steps taken since app started
      _steps = event.steps - _initialSteps;
      _updateStats();
    });

    await _saveStepsToFirestore();
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void _updateStats() {
    setState(() {
      // Calculate percentage if goal is set, otherwise show 0
      _percentage = _hasSetGoal ? (_steps / _goal * 100).clamp(0, 100) : 0;

      // Update calories and distance based on actual steps
      // Average calorie burn per step (varies by person)
      _calories = (_steps * 0.04).round();
      // Average stride length (in km) - can be adjusted based on user height
      _distance = _steps * 0.0007;
    });
  }

  Future<void> _saveStepsToFirestore() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Check if goal is completed
        if (_hasSetGoal && _steps >= _goal && !_goalCompleted) {
          setState(() {
            _goalCompleted = true;
          });
          // Record completed goal
          await _firestore.collection('step_history').add({
            'user_id': _userId,
            'steps': _steps,
            'goal': _goal,
            'date': Timestamp.fromDate(today),
            'completed': true,
          });
          
          // Allow setting new goal
          setState(() {
            _hasSetGoal = false;
            _goalCompleted = false;
          });
          
          // Show completion message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Congratulations! You\'ve reached your goal of $_goal steps!'),
                backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
            );
          }
        }

        // Save current stats
        await _firestore.collection('users').doc(_userId).update({
          'current_steps': _steps,
          'calories': _calories,
          'distance': _distance,
          'last_updated': FieldValue.serverTimestamp(),
          'date': Timestamp.fromDate(today),
        });

        // Save daily progress at end of day or when app closes
        if (_steps > 0) {
          await _firestore.collection('step_history').add({
            'user_id': _userId,
            'steps': _steps,
            'goal': _goal,
            'date': Timestamp.fromDate(today),
            'completed': _goalCompleted,
          });
        }
      }
    } catch (e) {
      print('No internet connection or error saving: $e');
    }
  }

  void _handleSensorError(String sensorName, dynamic error) {
    print('$sensorName error: $error');
    if (mounted) {
      _showError('$sensorName is not available on this device');
    }
  }

  Future<void> _showGoalSelectionSheet() async {
    try {
      // Get user's BMI from Firestore
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final userData = userDoc.data();
      
      double? bmi;
      if (userData != null && userData['weight'] != null && userData['height'] != null) {
        final weight = (userData['weight'] as num).toDouble();
        final height = (userData['height'] as num).toDouble() / 100; // convert to meters
        bmi = weight / (height * height);
      }

      // Get recommended goals based on BMI
      final recommendedGoals = await _stepGoalService.getRecommendedStepGoals(bmi ?? 25);

      final selectedGoal = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GoalSelectionSheet(
          recommendedGoals: recommendedGoals,
        ),
      );

      if (selectedGoal != null) {
        final now = DateTime.now();
        setState(() {
          _hasSetGoal = true;
          _goal = selectedGoal;
          _lastGoalSetDate = now;
          _updateStats();
        });

        try {
          await _firestore.collection('users').doc(_userId).update({
            'step_goal': selectedGoal,
            'goal_set_date': Timestamp.fromDate(now),
          });
        } catch (e) {
          print('Error saving goal: $e');
          _showError('Failed to save goal');
        }
      }
    } catch (e) {
      print('Error showing goal selection: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromRGBO(223, 77, 15, 1.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Summary',
          style: TextStyle(
            color: Color.fromRGBO(223, 77, 15, 1.0),
            fontSize: 16,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Track your steps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (!_hasSetGoal) ...[
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'SET ',
                      style: TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'goal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(flex: 1),
            Text(
              '$_steps',
              style: const TextStyle(
                color: Color.fromRGBO(223, 77, 15, 1.0),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'steps taken',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(340, 170),
                    painter: SemiCircleProgressPainter(
                      percentage: _percentage,
                      color: const Color.fromRGBO(223, 77, 15, 1.0),
                      goal: _goal,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${_percentage.round()}%',
                        style: const TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_hasSetGoal) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showGoalSelectionSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(100, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text(
                            'SET',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: _calories.toString(),
                  label: 'kcal',
                ),
                _buildStatCard(
                  icon: Icons.place,
                  value: _distance.toStringAsFixed(2),
                  label: 'total distance',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromRGBO(223, 77, 15, 1.0),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color.fromRGBO(223, 77, 15, 1.0),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SemiCircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final int goal;

  SemiCircleProgressPainter({
    required this.percentage,
    required this.color,
    required this.goal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paint,
    );

    // Draw progress arc if percentage > 0
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        (pi * percentage / 100),
        false,
        progressPaint,
      );
    }

    // Draw tick marks (lines instead of dots)
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Draw labels
    final textStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Left label (0)
    const leftTextSpan = TextSpan(
      text: '0',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final leftTextPainter = TextPainter(
      text: leftTextSpan,
      textDirection: TextDirection.ltr,
    );
    leftTextPainter.layout();
    leftTextPainter.paint(
      canvas,
      Offset(0, size.height - leftTextPainter.height),
    );

    // Right label (goal)
    final rightTextSpan = TextSpan(
      text: goal.toString(),
      style: textStyle,
    );
    final rightTextPainter = TextPainter(
      text: rightTextSpan,
      textDirection: TextDirection.ltr,
    );
    rightTextPainter.layout();
    rightTextPainter.paint(
      canvas,
      Offset(size.width - rightTextPainter.width, size.height - rightTextPainter.height),
    );
  }

  @override
  bool shouldRepaint(SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.goal != goal;
  }
}