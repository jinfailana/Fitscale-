import 'package:flutter/material.dart';
import 'dart:math' as math;

class SemiCircleProgressPainter extends CustomPainter {
  // Properties needed for drawing
  final double percentage;      // Progress percentage (0.0 to 1.0)
  final Color backgroundColor;  // Color of unfilled arc
  final Color progressColor;    // Color of progress arc
  final int goalSteps;         // Goal steps for labeling

  SemiCircleProgressPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
    required this.goalSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate center point and radius
    final center = Offset(size.width / 2, size.height - 40);
    final radius = size.width * 0.4;
    
    // 1. Draw background semi-circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,  // Start angle (180 degrees)
      math.pi,  // Sweep angle (180 degrees for semi-circle)
      false,    // Don't include center point
      backgroundPaint,
    );

    // 2. Draw progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;  // Rounded ends

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,                    // Start from 180 degrees
        math.pi * percentage,       // Draw based on progress
        false,
        progressPaint,
      );
    }

    // 3. Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 11 tick marks evenly spaced
    for (var i = 0; i <= 10; i++) {
      final angle = math.pi + (math.pi / 10) * i;  // Calculate angle for each tick
      
      // Calculate start and end points for tick mark
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

    // 4. Draw labels (0 and goal steps)
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    // Draw "0" on the left
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

    // Draw goal number on the right
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