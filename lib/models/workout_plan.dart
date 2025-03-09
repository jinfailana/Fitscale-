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
}

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String rest;
  final IconData icon;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.icon,
  });
}
