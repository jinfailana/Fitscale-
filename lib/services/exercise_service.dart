import 'package:flutter/material.dart';
import '../models/workout_plan.dart';

class ExerciseService {
  Exercise _parseExercise(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      sets: json['sets'] ?? '3',
      reps: json['reps'] ?? '12',
      rest: json['rest'] ?? '60',
      icon: _getExerciseIcon(json['target'] ?? ''),
      musclesWorked: json['musclesWorked'] ?? [],
      instructions: json['instructions'] ?? [],
      imageHtml: json['imageHtml'] ?? '',
    );
  }

  // Get exercise icon based on target muscle
  IconData _getExerciseIcon(String target) {
    switch (target.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'legs':
        return Icons.directions_run;
      case 'shoulders':
        return Icons.sports_handball;
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
        return Icons.sports_gymnastics;
      case 'cardio':
        return Icons.directions_run;
      case 'waist':
        return Icons.accessibility_new;
      case 'upper legs':
        return Icons.directions_run;
      case 'lower legs':
        return Icons.directions_run;
      case 'upper arms':
        return Icons.sports_martial_arts;
      case 'lower arms':
        return Icons.sports_martial_arts;
      default:
        return Icons.fitness_center;
    }
  }
}
