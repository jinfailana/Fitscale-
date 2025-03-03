import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math' as math;


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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadGoal();
  }

  void loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = prefs.getInt('step_goal') ?? 650;
      _steps = prefs.getInt('current_steps') ?? 0;
      _updateStats();
    });
  }

  void _updateStats() {
    setState(() {
      _percentage = (_steps / _goal) * 100;
      _calories = (_steps * 0.04).round();
      _distance = _steps * 0.0007;
    });
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
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
    setState(() {
      _selectedIndex = index;
    });
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
                          backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          selectedItemColor: const Color.fromRGBO(223, 77, 15, 1.0),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.fitness_center, 'Workouts', 1),
            _buildNavItem(Icons.history, 'History', 2),
            _buildNavItem(Icons.person, 'Me', 3),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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
    int? selectedGoal;  // Track the selected goal

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
                  const SizedBox(width: 40),  // For balance
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
                onPressed: selectedGoal == null ? null : () async {
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
                  disabledBackgroundColor: const Color.fromRGBO(223, 77, 15, 0.5),
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
    final goals = [
      {'steps': '2500', 'description': 'Become active'},
      {'steps': '5000', 'description': 'Keep fit'},
      {'steps': '8000', 'description': 'Boost metabolism'},
      {'steps': '15000', 'description': 'Lose weight'},
    ];

    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final currentGoal = int.parse(goals[index]['steps']!);
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
                  goals[index]['description']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${goals[index]['steps']} steps/day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    // Draw "0" labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: '0',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Left "0"
    textPainter.paint(
      canvas,
      Offset(center.dx - radius - 20, center.dy - 6),
    );
    
    // Right "0"
    textPainter.paint(
      canvas,
      Offset(center.dx + radius + 8, center.dy - 6),
    );

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
