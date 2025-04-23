import 'package:flutter/material.dart';
import '../models/workout_plan.dart';

class WorkoutCard extends StatefulWidget {
  final WorkoutPlan workout;
  final Function(WorkoutPlan) onAddToMyWorkouts;
  final bool isInMyWorkouts;
  final VoidCallback onTap;

  const WorkoutCard({
    Key? key,
    required this.workout,
    required this.onAddToMyWorkouts,
    required this.isInMyWorkouts,
    required this.onTap,
  }) : super(key: key);

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  bool _isAddingWorkout = false;

  Future<void> _handleAddToMyWorkouts() async {
    if (_isAddingWorkout) return;

    setState(() {
      _isAddingWorkout = true;
    });

    try {
      await widget.onAddToMyWorkouts(widget.workout);
    } finally {
      if (mounted) {
        setState(() {
          _isAddingWorkout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // ... existing code ...
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            // ... existing code ...
            if (!widget.isInMyWorkouts)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _isAddingWorkout ? null : _handleAddToMyWorkouts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                    foregroundColor: Colors.white,
                  ),
                  child: _isAddingWorkout
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add to My Workouts'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
