import 'package:flutter/material.dart';

class GoalSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> recommendedGoals;
  
  const GoalSelectionSheet({
    super.key,
    required this.recommendedGoals,
  });

  @override
  State<GoalSelectionSheet> createState() => _GoalSelectionSheetState();
}

class _GoalSelectionSheetState extends State<GoalSelectionSheet> {
  int? _selectedGoal;
  bool _isCustom = false;
  final List<int> _customGoals = [1000, 1500, 2000, 2500, 3000, 3500];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(51, 50, 50, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Daily Step Goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _isCustom = false;
                  _selectedGoal = null;
                }),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    color: !_isCustom 
                      ? const Color.fromRGBO(223, 77, 15, 1.0)
                      : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _isCustom = true;
                  _selectedGoal = null;
                }),
                child: Text(
                  'Custom',
                  style: TextStyle(
                    color: _isCustom 
                      ? const Color.fromRGBO(223, 77, 15, 1.0)
                      : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isCustom) ...[
            ...widget.recommendedGoals.map((goal) => _buildGoalOption(goal)),
          ] else ...[
            ..._customGoals.map((steps) => _buildCustomGoalOption(steps)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedGoal != null 
              ? () => Navigator.pop(context, _selectedGoal)
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomGoalOption(int steps) {
    final isSelected = _selectedGoal == steps;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = steps),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color.fromRGBO(223, 77, 15, 1.0)
            : const Color.fromRGBO(28, 28, 30, 1.0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            steps.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(Map<String, dynamic> goal) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goal['steps'] as int),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedGoal == goal['steps'] 
            ? const Color.fromRGBO(223, 77, 15, 1.0)
            : const Color.fromRGBO(28, 28, 30, 1.0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal['description'],
              style: TextStyle(
                color: _selectedGoal == goal['steps'] 
                  ? Colors.white70 
                  : Colors.grey,
                fontSize: 14,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal['steps']}',
                  style: TextStyle(
                    color: _selectedGoal == goal['steps'] 
                      ? Colors.white 
                      : Colors.grey,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'steps/day',
                  style: TextStyle(
                    color: _selectedGoal == goal['steps'] 
                      ? Colors.white70 
                      : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 