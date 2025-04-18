// lib/models/workout_plan.dart
import 'package:flutter/material.dart';

class WorkoutPlan {
  final String name;
  final String description;
  final IconData icon;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.name,
    required this.description,
    required this.icon,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconCode': icon.codePoint,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCode'] ?? 0xe1d8, fontFamily: 'MaterialIcons'),
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e))
              .toList() ??
          [],
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
  String gifUrl;
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
    this.gifUrl = '',
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
      'gifUrl': gifUrl,
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
      gifUrl: map['gifUrl'] ?? '',
      setsCompleted: map['setsCompleted'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'])
          : null,
    );
  }
}
