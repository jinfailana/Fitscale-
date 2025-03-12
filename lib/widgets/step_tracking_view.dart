import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'semi_circle_progress_painter.dart';

class StepTrackingView extends StatelessWidget {
  final int steps;
  final int goal;
  final double percentage;
  final int calories;
  final double distance;
  final String status;

  const StepTrackingView({
    Key? key,
    required this.steps,
    required this.goal,
    required this.percentage,
    required this.calories,
    required this.distance,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          
          const SizedBox(height: 24),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$steps',
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
                percentage: percentage / 100,
                backgroundColor: Colors.grey[800]!,
                progressColor: const Color.fromRGBO(223, 77, 15, 1.0),
                goalSteps: goal,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                icon: Icons.local_fire_department,
                value: '$calories',
                label: 'kcal',
              ),
              _buildStatCard(
                icon: Icons.location_on,
                value: '${distance.toStringAsFixed(1)}',
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