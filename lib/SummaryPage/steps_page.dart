import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';
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

  // Add this variable to track if user has set a goal
  bool _hasSetGoal = false;
  int _goal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingGoal();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingGoal() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['step_goal'] != null) {
          setState(() {
            _hasSetGoal = true;
            _goal = doc.data()?['step_goal'];
          });
          _initializeStepTracking();
        }
      }
    } catch (e) {
      print('Error checking goal: $e');
    }
  }

  Future<void> _showGoalSelectionSheet() async {
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
      setState(() {
        _hasSetGoal = true;
        _goal = selectedGoal;
      });
      
      // Save goal to Firestore
      try {
        await _firestore.collection('users').doc(_userId).update({
          'step_goal': selectedGoal,
          'goal_set_date': FieldValue.serverTimestamp(),
        });
        _initializeStepTracking();
      } catch (e) {
        print('Error saving goal: $e');
        _showError('Failed to save goal');
      }
    }
  }

  Future<void> _initializeStepTracking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      _userId = user.uid;
      await _requestPermissions();
      await _initializePedometer();
    } catch (e) {
      print('Error initializing step tracking: $e');
      _showError('Failed to initialize step tracking');
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
      body: _hasSetGoal ? _buildStepsTrackingUI() : _buildSetGoalUI(),
    );
  }

  Widget _buildSetGoalUI() {
    return Padding(
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
            child: CustomPaint(
              size: const Size(300, 150),
              painter: SemiCircleProgressPainter(
                percentage: 0,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
              child: const SizedBox(
                height: 150,
                width: 300,
                child: Center(
                  child: Text(
                    '0%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _showGoalSelectionSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(100, 40),
              ),
              child: const Text(
                'SET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.local_fire_department,
                value: '0',
                label: 'kcal',
              ),
              _buildStatCard(
                icon: Icons.place,
                value: '0',
                label: 'total distance',
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepsTrackingUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Steps Taken',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$_steps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.local_fire_department,
                value: '$_calories',
                label: 'kcal',
              ),
              _buildStatCard(
                icon: Icons.place,
                value: _distance.toStringAsFixed(2),
                label: 'km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(28, 28, 30, 1.0),
        borderRadius: BorderRadius.circular(20),
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
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Add this class for the semi-circle progress
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

    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(dotCenter, 2, dotPaint);
    }

    // Draw 0 labels
    const textStyle = TextStyle(color: Colors.grey, fontSize: 12);
    final textSpan = TextSpan(text: '0', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Left 0
    textPainter.paint(canvas, Offset(0, size.height - textPainter.height));
    // Right 0
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width, size.height - textPainter.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
