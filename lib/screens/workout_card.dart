import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import 'workout_details_page.dart';

class WorkoutCard extends StatefulWidget {
  final WorkoutPlan workout;
  final Function(WorkoutPlan) onAddToWorkoutList;
  final bool isInMyWorkouts;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onAddToWorkoutList,
    this.isInMyWorkouts = false,
  });

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  late bool _isInMyWorkouts;

  @override
  void initState() {
    super.initState();
    _isInMyWorkouts = widget.isInMyWorkouts;
  }

  @override
  void didUpdateWidget(WorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInMyWorkouts != widget.isInMyWorkouts) {
      setState(() {
        _isInMyWorkouts = widget.isInMyWorkouts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromRGBO(28, 28, 30, 1.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(
          color: Color.fromRGBO(223, 77, 15, 1.0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailsPage(
                workout: widget.workout,
                onAddToWorkoutList: widget.onAddToWorkoutList,
                isFromMyWorkouts: _isInMyWorkouts,
              ),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isInMyWorkouts = widget.isInMyWorkouts;
              });
            }
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(_extractImageUrl(
                          widget.workout.exercises.first.imageHtml)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!_isInMyWorkouts)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_isInMyWorkouts) {
                          widget.onAddToWorkoutList(widget.workout);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to My Workouts'),
                              backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
                            ),
                          );
                          if (mounted) {
                            setState(() {
                              _isInMyWorkouts = true;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add to My Workouts',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(223, 77, 15, 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.workout.icon,
                        color: const Color.fromRGBO(223, 77, 15, 1.0),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.workout.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractImageUrl(String imageHtml) {
    final regExp = RegExp(r'src="([^"]+)"');
    final match = regExp.firstMatch(imageHtml);
    return match?.group(1) ?? '';
  }
}
