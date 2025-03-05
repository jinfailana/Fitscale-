import 'package:flutter/material.dart';

// 1. Workout History Item
class HistoryItem extends StatelessWidget {
  final String icon;      // Workout icon/image
  final String title;     // Workout name (e.g., "Back Workout")
  final String date;      // Date of workout

  // Constructor
  const HistoryItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ... container styling ...
      child: Row(
        children: [
          Image.asset(icon),           // Shows workout type image
          Column(
            children: [
              Text(title),             // Shows workout name
              Text(date),              // Shows workout date
            ],
          ),
        ],
      ),
    );
  }
}

// 2. Steps History Item
class StepsItem extends StatelessWidget {
  final int steps;       // Number of steps taken
  final String date;     // Date of step count

  // Constructor
  const StepsItem({
    Key? key,
    required this.steps,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ... container styling ...
      child: Row(
        children: [
          Icon(Icons.directions_walk),  // Steps icon
          Column(
            children: [
              Text('Steps Taken'),
              Text('$steps Steps'),     // Shows step count
              Text(date),               // Shows date
            ],
          ),
        ],
      ),
    );
  }
}

// 3. Diet History Item
class DietItem extends StatelessWidget {
  final String title;    // Diet type (e.g., "Low-Fat")
  final String date;     // Date of diet record

  // Constructor
  const DietItem({
    Key? key,
    required this.title,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ... container styling ...
      child: Row(
        children: [
          Column(
            children: [
              Text(title),              // Shows diet type
              Row(
                children: [
                  Text('View Diet'),    // View diet button
                  Icon(Icons.restaurant_menu),
                ],
              ),
              Text(date),              // Shows date
            ],
          ),
        ],
      ),
    );
  }
}
