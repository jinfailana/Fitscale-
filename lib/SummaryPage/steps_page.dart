import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' show pi, cos, sin;
import '../widgets/goal_selection_sheet.dart';

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
        await _checkExistingGoal();
        await _requestPermissions();
        await _initializePedometer();
      }
    } catch (e) {
      print('Error initializing tracking: $e');
      _showError('Failed to initialize tracking');
    }
  }

  Future<void> _checkExistingGoal() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['step_goal'] != null) {
          setState(() {
            _hasSetGoal = true;
            _goal = data?['step_goal'];
          });

          // Check last goal set date
          if (data?['goal_set_date'] != null) {
            _lastGoalSetDate = (data?['goal_set_date'] as Timestamp).toDate();
          }
        }
      }
    } catch (e) {
      print('Error checking goal: $e');
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
    setState(() {
      _steps = event.steps;
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

      // Calculate calories and distance regardless of goal
      _calories = (_steps * 0.04).round();
      _distance = _steps * 0.0007;
    });
  }

  Future<void> _saveStepsToFirestore() async {
    try {
      await _firestore.collection('users').doc(_userId).update({
        'current_steps': _steps,
        'calories': _calories,
        'distance': _distance,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving steps: $e');
    }
  }

  void _handleSensorError(String sensorName, dynamic error) {
    print('$sensorName error: $error');
    if (mounted) {
      _showError('$sensorName is not available on this device');
    }
  }

  Future<void> _showGoalSelectionSheet() async {
    // Check if goal was set today
    if (_lastGoalSetDate != null) {
      final now = DateTime.now();
      final lastSetDate = DateTime(_lastGoalSetDate!.year,
          _lastGoalSetDate!.month, _lastGoalSetDate!.day);
      final today = DateTime(now.year, now.month, now.day);

      if (lastSetDate == today) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only set a new goal once per day'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final selectedGoal = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSelectionSheet(
        recommendedGoals: [
          {'steps': 2500, 'description': 'Become active'},
          {'steps': 5000, 'description': 'Keep fit'},
          {'steps': 8000, 'description': 'Boost metabolism'},
          {'steps': 15000, 'description': 'Lose weight'},
        ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track your steps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'SET ',
                    style: TextStyle(
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'goal',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(300, 150),
                    painter: SemiCircleProgressPainter(
                      percentage: _percentage,
                      color: const Color.fromRGBO(223, 77, 15, 1.0),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${_percentage.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showGoalSelectionSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(223, 77, 15, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('SET'),
                      ),
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

  SemiCircleProgressPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 8.0 // Thicker line
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
        ..strokeWidth = 8.0 // Thicker line
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

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3.0 // Slightly thicker ticks
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final outerPoint = Offset(
        center.dx + (radius) * cos(angle),
        center.dy + (radius) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Draw 0 labels
    const textStyle = TextStyle(
      color: Colors.grey,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Left 0
    final leftTextSpan = TextSpan(text: '0', style: textStyle);
    final leftTextPainter = TextPainter(
      text: leftTextSpan,
      textDirection: TextDirection.ltr,
    );
    leftTextPainter.layout();
    leftTextPainter.paint(
      canvas,
      Offset(0, size.height - leftTextPainter.height),
    );

    // Right 0
    final rightTextSpan = TextSpan(text: '0', style: textStyle);
    final rightTextPainter = TextPainter(
      text: rightTextSpan,
      textDirection: TextDirection.ltr,
    );
    rightTextPainter.layout();
    rightTextPainter.paint(
      canvas,
      Offset(size.width - rightTextPainter.width,
          size.height - rightTextPainter.height),
    );
  }

  @override
  bool shouldRepaint(SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
