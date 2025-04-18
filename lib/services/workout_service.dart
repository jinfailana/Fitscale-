import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../models/user_model.dart';
import 'exercise_service.dart';

class WorkoutService {
  final ExerciseService _exerciseService = ExerciseService();

  Future<List<WorkoutPlan>> generateRecommendations(UserModel user) async {
    List<WorkoutPlan> recommendations = [];
    String intensity = _calculateIntensity(user);
    bool hasGymAccess = user.workoutPlace?.toLowerCase() == "gym";
    List<String> availableEquipment = user.gymEquipment ?? [];
    String workoutDuration = _calculateWorkoutDuration(user);

    try {
      // Get all exercises from the API
      final allExercises = await _exerciseService.getAllExercises();

      // Filter exercises based on equipment availability
      final filteredExercises = allExercises.where((exercise) {
        if (!hasGymAccess) {
          return exercise['equipment']?.toLowerCase() == 'bodyweight' ||
              exercise['equipment']?.toLowerCase() == 'dumbbell';
        }
        return true;
      }).toList();

      if (filteredExercises.isEmpty) {
        throw Exception('No exercises found matching the criteria');
      }

      // Generate workouts based on user's goal
      if (user.goal?.toLowerCase() == "lose weight") {
        recommendations.addAll(await _getWeightLossWorkouts(
          intensity: intensity,
          exercises: filteredExercises,
          duration: workoutDuration,
        ));
      } else if (user.goal?.toLowerCase() == "build muscle") {
        recommendations.addAll(await _getMuscleGainWorkouts(
          intensity: intensity,
          exercises: filteredExercises,
          duration: workoutDuration,
        ));
      } else {
        recommendations.addAll(await _getGeneralFitnessWorkouts(
          intensity: intensity,
          exercises: filteredExercises,
          duration: workoutDuration,
        ));
      }

      return recommendations;
    } catch (e) {
      print('Error generating recommendations: $e');
      // Return a basic workout plan with a message about the error
      return [
        WorkoutPlan(
          name: "Workout Plan",
          description:
              "Unable to load exercises. Please check your internet connection and try again.",
          icon: Icons.error_outline,
          exercises: [],
        )
      ];
    }
  }

  String _calculateIntensity(UserModel user) {
    int intensityScore = 0;

    switch (user.activityLevel?.toLowerCase()) {
      case "sedentary":
        intensityScore += 1;
        break;
      case "lightly active":
        intensityScore += 2;
        break;
      case "moderately active":
        intensityScore += 3;
        break;
      case "very active":
        intensityScore += 4;
        break;
    }

    switch (user.expertiseLevel?.toLowerCase()) {
      case "beginner":
        intensityScore += 1;
        break;
      case "intermediate":
        intensityScore += 2;
        break;
      case "advanced":
        intensityScore += 3;
        break;
    }

    if (intensityScore <= 3) return "beginner";
    if (intensityScore <= 5) return "intermediate";
    return "advanced";
  }

  String _calculateWorkoutDuration(UserModel user) {
    int baseDuration = 45;

    switch (user.activityLevel?.toLowerCase()) {
      case "sedentary":
        baseDuration = 30;
        break;
      case "very active":
        baseDuration = 60;
        break;
    }

    if (user.goal?.toLowerCase() == "lose weight") {
      baseDuration += 15;
    }

    return "$baseDuration min";
  }

  Future<List<WorkoutPlan>> _getWeightLossWorkouts({
    required String intensity,
    required List<Map<String, dynamic>> exercises,
    required String duration,
  }) async {
    // Filter exercises suitable for weight loss
    final cardioExercises = exercises
        .where((e) =>
            e['target']?.toLowerCase().contains('cardio') ??
            false || e['bodyPart']?.toLowerCase().contains('cardio') ??
            false)
        .toList();

    final strengthExercises = exercises
        .where((e) =>
            e['target']?.toLowerCase().contains('strength') ??
            false || e['bodyPart']?.toLowerCase().contains('strength') ??
            false)
        .toList();

    return [
      WorkoutPlan(
        name: "Fat Burning Program",
        description: "High-intensity workout focused on calorie burn",
        icon: Icons.local_fire_department,
        exercises: _createExercisesList(
          cardioExercises.take(2).toList(),
          strengthExercises.take(2).toList(),
          intensity,
        ),
      ),
      WorkoutPlan(
        name: "Metabolic Conditioning",
        description: "Circuit training to maximize calorie burn",
        icon: Icons.whatshot,
        exercises: _createExercisesList(
          cardioExercises.skip(2).take(2).toList(),
          strengthExercises.skip(2).take(2).toList(),
          intensity,
        ),
      ),
    ];
  }

  Future<List<WorkoutPlan>> _getMuscleGainWorkouts({
    required String intensity,
    required List<Map<String, dynamic>> exercises,
    required String duration,
  }) async {
    // Filter exercises suitable for muscle gain
    final strengthExercises = exercises
        .where((e) =>
            e['target']?.toLowerCase().contains('strength') ??
            false || e['bodyPart']?.toLowerCase().contains('strength') ??
            false)
        .toList();

    return [
      WorkoutPlan(
        name: "Strength Training",
        description: "Focus on building muscle mass and strength",
        icon: Icons.fitness_center,
        exercises: _createExercisesList(
          strengthExercises.take(4).toList(),
          [],
          intensity,
        ),
      ),
      WorkoutPlan(
        name: "Power Building",
        description: "Combine strength and power exercises",
        icon: Icons.power,
        exercises: _createExercisesList(
          strengthExercises.skip(4).take(4).toList(),
          [],
          intensity,
        ),
      ),
    ];
  }

  Future<List<WorkoutPlan>> _getGeneralFitnessWorkouts({
    required String intensity,
    required List<Map<String, dynamic>> exercises,
    required String duration,
  }) async {
    // Mix of different exercise types
    final mixedExercises = exercises.toList()..shuffle();

    return [
      WorkoutPlan(
        name: "Full Body Fitness",
        description: "Balanced workout for overall fitness",
        icon: Icons.sports_gymnastics,
        exercises: _createExercisesList(
          mixedExercises.take(4).toList(),
          [],
          intensity,
        ),
      ),
      WorkoutPlan(
        name: "Functional Training",
        description: "Improve daily movement patterns",
        icon: Icons.accessibility_new,
        exercises: _createExercisesList(
          mixedExercises.skip(4).take(4).toList(),
          [],
          intensity,
        ),
      ),
    ];
  }

  List<Exercise> _createExercisesList(
    List<Map<String, dynamic>> primaryExercises,
    List<Map<String, dynamic>> secondaryExercises,
    String intensity,
  ) {
    final exercises = <Exercise>[];

    for (var exercise in primaryExercises) {
      exercises.add(Exercise(
        name: exercise['name'] ?? '',
        sets: _getIntensityBasedSets(intensity),
        reps: _getIntensityBasedReps(intensity),
        rest: _getIntensityBasedRest(intensity),
        icon: _getExerciseIcon(exercise['target'] ?? ''),
        musclesWorked: [
          exercise['target'] ?? '',
          ...(exercise['secondaryMuscles'] ?? []),
        ],
        instructions: exercise['instructions'] ?? [],
        gifUrl: exercise['gifUrl'] ?? '',
      ));
    }

    for (var exercise in secondaryExercises) {
      exercises.add(Exercise(
        name: exercise['name'] ?? '',
        sets: _getIntensityBasedSets(intensity),
        reps: _getIntensityBasedReps(intensity),
        rest: _getIntensityBasedRest(intensity),
        icon: _getExerciseIcon(exercise['target'] ?? ''),
        musclesWorked: [
          exercise['target'] ?? '',
          ...(exercise['secondaryMuscles'] ?? []),
        ],
        instructions: exercise['instructions'] ?? [],
        gifUrl: exercise['gifUrl'] ?? '',
      ));
    }

    return exercises;
  }

  String _getIntensityBasedSets(String intensity) {
    switch (intensity.toLowerCase()) {
      case "beginner":
        return "2";
      case "intermediate":
        return "3";
      case "advanced":
        return "4";
      default:
        return "3";
    }
  }

  String _getIntensityBasedReps(String intensity) {
    switch (intensity.toLowerCase()) {
      case "beginner":
        return "8-10";
      case "intermediate":
        return "10-12";
      case "advanced":
        return "12-15";
      default:
        return "10-12";
    }
  }

  String _getIntensityBasedRest(String intensity) {
    switch (intensity.toLowerCase()) {
      case "beginner":
        return "90 sec";
      case "intermediate":
        return "60 sec";
      case "advanced":
        return "45 sec";
      default:
        return "60 sec";
    }
  }

  IconData _getExerciseIcon(String target) {
    switch (target.toLowerCase()) {
      case "cardio":
        return Icons.directions_run;
      case "strength":
        return Icons.fitness_center;
      case "flexibility":
        return Icons.self_improvement;
      default:
        return Icons.sports_gymnastics;
    }
  }
}
