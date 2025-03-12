import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pedometer/pedometer.dart'; // Add this package
import 'package:permission_handler/permission_handler.dart'; // Add this package
import 'dart:math' as math;
import '../services/step_goals_service.dart';
import '../widgets/goal_selection_sheet.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  final StepGoalsService _stepGoalsService = StepGoalsService();
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  
  // Step tracking variables
  int _steps = 0;
  int _goal = 650;
  double _percentage = 0;
  int _calories = 0;
  double _distance = 0;
  int? _lastGoalSetDate;
  String _status = 'unknown';
  int _initialSteps = 0;
  int _stepsSinceGoal = 0;
  bool _hasSetGoal = false;  // Add this to track if goal is set

  @override
  void initState() {
    super.initState();
    _checkExistingGoal();
    _requestPermissions();
  }

  Future<void> _checkExistingGoal() async {
    try {
      final goal = await _stepGoalsService.getUserGoal();
      setState(() {
        _goal = goal;
        _hasSetGoal = goal != 0;  // Set to true if there's an existing goal
        if (_hasSetGoal) {
          _updateStats();
        }
      });
    } catch (e) {
      print('Error loading user goal: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.activityRecognition.request().isGranted) {
      initPlatformState();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('This app needs activity recognition permission to count your steps.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void initPlatformState() {
    _stepCountStream = Pedometer.stepCountStream;
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

    _stepCountStream.listen(onStepCount).onError(onStepCountError);
    _pedestrianStatusStream.listen(onPedestrianStatusChanged);
  }

  void onStepCount(StepCount event) {
    setState(() {
      if (_initialSteps == 0) {
        _initialSteps = event.steps;
      }
      _steps = event.steps;
      _stepsSinceGoal = _steps - _initialSteps;
      _updateStats();
    });
  }

  void onStepCountError(error) {
    print('Step count error: $error');
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void _updateStats() {
    setState(() {
      _percentage = (_stepsSinceGoal / _goal) * 100;
      _calories = (_stepsSinceGoal * 0.04).round();
      _distance = _stepsSinceGoal * 0.0007;
    });
  }

  Future<void> _showSetGoalDialog() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (_lastGoalSetDate != null) {
        final today = DateTime.now();
        final lastSet = DateTime.fromMillisecondsSinceEpoch(_lastGoalSetDate!);
        
        if (today.year == lastSet.year && 
            today.month == lastSet.month && 
            today.day == lastSet.day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can only set your goal once per day. Try again tomorrow.',
                style: TextStyle(color: Colors.orange),
              ),
              backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
            ),
          );
          return;
        }
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data()!;
      final double height = userData['height'] ?? 170;
      final double weight = userData['weight'] ?? 70;
      final int birthYear = userData['birthYear'] ?? 2000;

      final double bmi = weight / (height / 100 * height / 100);
      final int age = DateTime.now().year - birthYear;

      final recommendedGoals = await _stepGoalsService.getRecommendedGoals(bmi, age);

      final selectedGoal = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => GoalSelectionSheet(
          recommendedGoals: recommendedGoals,
        ),
      );

      if (selectedGoal != null) {
        await _stepGoalsService.saveUserGoal(selectedGoal);
        setState(() {
          _goal = selectedGoal;
          _lastGoalSetDate = DateTime.now().millisecondsSinceEpoch;
          _initialSteps = _steps;
          _stepsSinceGoal = 0;
          _updateStats();
        });
      }
    } catch (e) {
      print('Error setting goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error setting goal. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Summary',
          style: TextStyle(
            color: Color.fromRGBO(223, 77, 15, 1.0),
            fontSize: 16,
          ),
        ),
      ),
      body: _hasSetGoal ? _buildTrackingUI() : _buildSetGoalUI(),
    );
  }

  Widget _buildSetGoalUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Track your steps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/footsteps.png',  // Add footsteps icon
                width: 24,
                height: 24,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                'SET',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: SemiCircleProgressPainter(
                percentage: 0,
                backgroundColor: Colors.grey[800]!,
                progressColor: const Color.fromRGBO(223, 77, 15, 1.0),
                goalSteps: 0,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '0%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showSetGoalDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEmptyStatCard(
                icon: Icons.local_fire_department,
                value: '0',
                label: 'kcal',
              ),
              _buildEmptyStatCard(
                icon: Icons.location_on,
                value: '0',
                label: 'total distance',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatCard({
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

  Widget _buildTrackingUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Steps Taken',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Track your steps',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$_stepsSinceGoal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: ' steps',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You are on track to it! Keep it up.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: SemiCircleProgressPainter(
                percentage: _percentage / 100,
                backgroundColor: Colors.grey[800]!,
                progressColor: const Color.fromRGBO(223, 77, 15, 1.0),
                goalSteps: _goal,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_goal - _stepsSinceGoal} steps left',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                icon: Icons.local_fire_department,
                value: '${_calories}+',
                label: 'kcal',
              ),
              _buildStatCard(
                icon: Icons.location_on,
                value: '${_distance.toStringAsFixed(1)}m',
                label: 'total distance',
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

class SemiCircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;
  final int goalSteps;

  SemiCircleProgressPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
    required this.goalSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 40);
    final radius = size.width * 0.4;
    
    // Draw background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Draw progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * percentage,
        false,
        progressPaint,
      );
    }

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i <= 10; i++) {
      final angle = math.pi + (math.pi / 10) * i;
      final p1 = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 10) * math.cos(angle),
        center.dy + (radius + 10) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draw numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    // Draw "0"
    textPainter.text = const TextSpan(
      text: '0',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - radius - 20, center.dy + 10),
    );

    // Draw goal number
    textPainter.text = TextSpan(
      text: goalSteps.toString(),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + radius + 5, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
