import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../HistoryPage/history.dart';
import 'summary_page.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  int _steps = 0;
  int _goal = 650; // Default goal
  double _percentage = 0;
  int _calories = 0;
  double _distance = 0;
  int _selectedIndex = 1; // Set to 1 for Workouts tab
  Map<String, dynamic>? _userData;
  double? _bmi;
  String _bmiCategory = '';

  @override
  void initState() {
    super.initState();
    loadGoal();
    fetchUserDataAndCalculateBMI();
  }

  void loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = prefs.getInt('step_goal') ?? 650;
      _steps = prefs.getInt('current_steps') ?? 0;
      _updateStats();
    });
  }

  Future<void> fetchUserDataAndCalculateBMI() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = doc.data()!;
          setState(() {
            _userData = userData;
            // Calculate BMI
            double heightInMeters = (userData['height'] ?? 170) / 100;
            double weight = userData['weight']?.toDouble() ?? 70;
            _bmi = weight / (heightInMeters * heightInMeters);
            _bmiCategory = _getBMICategory(_bmi!);
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Overweight';
    return 'Obese';
  }

  List<Map<String, dynamic>> _calculateStepGoalsByBMI() {
    // Default values if BMI is not available
    if (_bmi == null) {
      return [
        {'title': 'Become active', 'steps': 3000},
        {'title': 'Keep fit', 'steps': 7000},
        {'title': 'Boost metabolism', 'steps': 10000},
        {'title': 'Lose weight', 'steps': 12000},
      ];
    }

    // Base step goals according to BMI category
    int becomeActiveBase;
    int keepFitBase;
    int boostMetabolismBase;
    int loseWeightBase;

    if (_bmi! < 18.5) {
      // Underweight
      // Focus on building strength and healthy weight gain
      becomeActiveBase = 3000;
      keepFitBase = 6000;
      boostMetabolismBase = 8000;
      loseWeightBase = 9000; // Lower for underweight (focus on nutrition)
    } else if (_bmi! < 25) {
      // Normal weight
      // Maintain healthy weight and fitness
      becomeActiveBase = 4000;
      keepFitBase = 7500;
      boostMetabolismBase = 10000;
      loseWeightBase = 12000;
    } else if (_bmi! < 30) {
      // Overweight
      // Focus on gradual weight loss and increased activity
      becomeActiveBase = 5000;
      keepFitBase = 8000;
      boostMetabolismBase = 11000;
      loseWeightBase = 13000;
    } else if (_bmi! < 35) {
      // Obese Class I
      // Start with achievable goals, gradually increase
      becomeActiveBase = 4000;
      keepFitBase = 7000;
      boostMetabolismBase = 9000;
      loseWeightBase = 11000;
    } else {
      // Obese Class II and above
      // Start with lower goals to prevent injury
      becomeActiveBase = 3000;
      keepFitBase = 6000;
      boostMetabolismBase = 8000;
      loseWeightBase = 10000;
    }

    // Age adjustment
    int age = DateTime.now().year - ((_userData?['birthYear'] ?? 2000) as int);
    double ageMultiplier = 1.0;

    if (age > 70) {
      ageMultiplier = 0.7; // Significant reduction for elderly
    } else if (age > 60) {
      ageMultiplier = 0.8; // Moderate reduction for seniors
    } else if (age > 50) {
      ageMultiplier = 0.9; // Slight reduction for older adults
    } else if (age < 18) {
      ageMultiplier = 1.2; // Increase for adolescents (more active)
    }

    // Apply age adjustment
    becomeActiveBase = (becomeActiveBase * ageMultiplier).round();
    keepFitBase = (keepFitBase * ageMultiplier).round();
    boostMetabolismBase = (boostMetabolismBase * ageMultiplier).round();
    loseWeightBase = (loseWeightBase * ageMultiplier).round();

    // Round to nearest 500 for cleaner numbers
    becomeActiveBase = (becomeActiveBase / 500).round() * 500;
    keepFitBase = (keepFitBase / 500).round() * 500;
    boostMetabolismBase = (boostMetabolismBase / 500).round() * 500;
    loseWeightBase = (loseWeightBase / 500).round() * 500;

    return [
      {'title': 'Become active', 'steps': becomeActiveBase},
      {'title': 'Keep fit', 'steps': keepFitBase},
      {'title': 'Boost metabolism', 'steps': boostMetabolismBase},
      {'title': 'Lose weight', 'steps': loseWeightBase},
    ];
  }

  void _updateStats() {
    setState(() {
      _percentage = (_steps / _goal) * 100;
      _calories = (_steps * 0.04).round();
      _distance = _steps * 0.0007;
    });
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(_selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon,
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.white54),
      ),
      label: label,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Handle navigation
    if (index == 0) {
      // Navigate to Summary page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SummaryPage()),
      );
    } else if (index == 2) {
      // Navigate to History page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    } else if (index == 3) {
      // Navigate to Profile/Me page
      // Add your profile page navigation here
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Track your steps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_walk,
                    color: Colors.grey[600],
                    size: 32,
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 350),
                    painter: SemiCircleProgressPainter(
                      percentage: _percentage / 100,
                      backgroundColor: Colors.grey[800]!,
                      progressColor: const Color.fromRGBO(223, 77, 15, 1.0),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    child: Text(
                      '${_percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(223, 77, 15, 1.0),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(223, 77, 15, 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showSetGoalDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(223, 77, 15, 1.0),
                          minimumSize: const Size(100, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SET',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularStatCard(
                  icon: Icons.local_fire_department,
                  value: '$_calories',
                  label: 'kcal',
                  progress: _calories / 1000,
                ),
                _buildCircularStatCard(
                  icon: Icons.location_on,
                  value: _distance.toStringAsFixed(1),
                  label: 'total distance',
                  progress: _distance / 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularStatCard({
    required IconData icon,
    required String value,
    required String label,
    required double progress,
  }) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(150, 150),
            painter: CircularProgressPainter(
              progress: progress,
              backgroundColor: Colors.grey[800]!,
              progressColor: const Color.fromRGBO(223, 77, 15, 1.0),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
                size: 50,
              ),
              const SizedBox(height: 60),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSetGoalDialog() async {
    bool isRecommended = true;
    int? selectedGoal; // Track the selected goal

    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Daily Step Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // For balance
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isRecommended = true),
                    child: Text(
                      'Recommended',
                      style: TextStyle(
                        color: isRecommended
                            ? const Color.fromRGBO(223, 77, 15, 1.0)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isRecommended = false),
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        color: !isRecommended
                            ? const Color.fromRGBO(223, 77, 15, 1.0)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isRecommended
                    ? _buildRecommendedGoals(selectedGoal, (goal) {
                        setState(() => selectedGoal = goal);
                      })
                    : _buildCustomGoals(selectedGoal, (goal) {
                        setState(() => selectedGoal = goal);
                      }),
              ),
              ElevatedButton(
                onPressed: selectedGoal == null
                    ? null
                    : () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('step_goal', selectedGoal!);
                        setState(() {
                          _goal = selectedGoal!;
                          _updateStats();
                        });
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // Button will be semi-transparent when disabled
                  disabledBackgroundColor:
                      const Color.fromRGBO(223, 77, 15, 0.5),
                ),
                child: const Text(
                  'Done',
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
    );
  }

  Widget _buildRecommendedGoals(int? selectedGoal, Function(int) onSelect) {
    if (_userData == null || _bmi == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(223, 77, 15, 1.0),
        ),
      );
    }

    final goals = _calculateStepGoalsByBMI();

    return Column(
      children: [
        // BMI Information Card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(45, 45, 45, 1.0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your BMI: ${_bmi!.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Category: $_bmiCategory',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Goals List
        Expanded(
          child: ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final currentGoal = goals[index]['steps'] as int;
              final isSelected = selectedGoal == currentGoal;

              return GestureDetector(
                onTap: () => onSelect(currentGoal),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromRGBO(223, 77, 15, 1.0)
                        : const Color.fromRGBO(45, 45, 45, 1.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goals[index]['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goals[index]['steps']} steps/day',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomGoals(int? selectedGoal, Function(int) onSelect) {
    final customGoals = [1000, 1500, 2000, 2500, 3000, 3500];

    return ListView.builder(
      itemCount: customGoals.length,
      itemBuilder: (context, index) {
        final isSelected = selectedGoal == customGoals[index];

        return GestureDetector(
          onTap: () => onSelect(customGoals[index]),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromRGBO(223, 77, 15, 1.0)
                  : const Color.fromRGBO(45, 45, 45, 1.0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${customGoals[index]}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SemiCircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;

  SemiCircleProgressPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 150);
    final radius = size.width * 0.40;
    final meterStrokeWidth = 25.0;
    final borderStrokeWidth = 3.0;
    final borderOffset = 12.0;

    // Draw black background arc
    final blackBackgroundPaint = Paint()
      ..color = const Color.fromRGBO(28, 28, 30, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = meterStrokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      blackBackgroundPaint,
    );

    // Draw orange border
    final borderPaint = Paint()
      ..color = const Color.fromRGBO(223, 77, 15, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderStrokeWidth;

    // Draw outer border
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + borderOffset),
      math.pi,
      math.pi,
      false,
      borderPaint,
    );

    // Draw inner border
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - borderOffset),
      math.pi,
      math.pi,
      false,
      borderPaint,
    );

    // Draw progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = meterStrokeWidth
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
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw tick marks
    for (var i = 0; i <= 20; i++) {
      final isLongTick = i % 2 == 0;
      final angle = math.pi + (math.pi / 20) * i;
      final tickLength = isLongTick ? 12.0 : 8.0;

      final startPoint = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius + tickLength) * math.cos(angle),
        center.dy + (radius + tickLength) * math.sin(angle),
      );

      canvas.drawLine(
        startPoint,
        endPoint,
        tickPaint..strokeWidth = isLongTick ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 7);
    final radius = size.width * 0.40;
    final strokeWidth = 10.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
