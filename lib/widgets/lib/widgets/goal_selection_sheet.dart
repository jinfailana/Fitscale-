import 'package:flutter/material.dart';

class GoalSelectionSheet extends StatelessWidget {
  final List<Map<String, dynamic>> recommendedGoals;

  const GoalSelectionSheet({
    Key? key,
    required this.recommendedGoals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(51, 50, 50, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Select Your Goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendedGoals.map((goal) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(28, 28, 30, 1.0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromRGBO(223, 77, 15, 0.3),
                width: 1,
              ),
            ),
            child: ListTile(
              title: Text(
                goal['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${goal['steps']} steps',
                style: const TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 14,
                ),
              ),
              onTap: () => Navigator.pop(context, goal['steps']),
            ),
          )).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 