// lib/models/workout_plan.dart
import 'package:flutter/material.dart';

class WorkoutPlan {
  final String name;
  final String description;
  final IconData icon;
  final List<Exercise> exercises;
  DateTime? lastCompleted;

  WorkoutPlan({
    required this.name,
    required this.description,
    required this.icon,
    required this.exercises,
    this.lastCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'lastCompleted': lastCompleted?.toIso8601String(),
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      name: map['name'] as String,
      description: map['description'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'] as String)
          : null,
    );
  }

  double get progressPercentage {
    if (exercises.isEmpty) return 0;
    final totalSets = exercises.fold<int>(
        0, (sum, exercise) => sum + (int.tryParse(exercise.sets) ?? 0));
    final completedSets =
        exercises.fold<int>(0, (sum, exercise) => sum + exercise.setsCompleted);
    return totalSets > 0 ? (completedSets / totalSets) * 100 : 0;
  }

  bool get isCompleted => progressPercentage >= 100;

  bool get isInProgress =>
      exercises.any((exercise) => exercise.setsCompleted > 0) && !isCompleted;
}

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String rest;
  final IconData icon;
  final List<String> musclesWorked;
  final List<String> instructions;
  String imageHtml;
  int setsCompleted;
  bool isCompleted;
  DateTime? lastCompleted;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.icon,
    required this.musclesWorked,
    required this.instructions,
    this.imageHtml =
        "<img src=\"\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
    this.setsCompleted = 0,
    this.isCompleted = false,
    this.lastCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'iconCode': icon.codePoint,
      'musclesWorked': musclesWorked,
      'instructions': instructions,
      'imageHtml': imageHtml,
      'setsCompleted': setsCompleted,
      'isCompleted': isCompleted,
      'lastCompleted': lastCompleted?.toIso8601String(),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      sets: map['sets'] ?? '',
      reps: map['reps'] ?? '',
      rest: map['rest'] ?? '',
      icon: IconData(map['iconCode'] ?? 0xe1d8, fontFamily: 'MaterialIcons'),
      musclesWorked: List<String>.from(map['musclesWorked'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      imageHtml: map['imageHtml'] ?? '',
      setsCompleted: map['setsCompleted'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'])
          : null,
    );
  }
}
