import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/workout_plan.dart';

class ExerciseService {
  // ExerciseDB API endpoint
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  static const Map<String, String> _headers = {
    'X-RapidAPI-Key': '3d093f5b58mshd807261fbdb710ap16b0a8jsn1c452bc6f2a5',
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com'
  };

  // Cache for exercises to avoid repeated API calls
  List<Map<String, dynamic>>? _cachedExercises;

  // Get all exercises from the API
  Future<List<Map<String, dynamic>>> getAllExercises() async {
    // Return cached exercises if available
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedExercises = data.cast<Map<String, dynamic>>();
        return _cachedExercises!;
      } else {
        print(
            'Failed to load exercises: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      throw Exception('Error fetching exercises: $e');
    }
  }

  // Fetch exercises with filters
  Future<List<Exercise>> fetchExercises({
    String? target,
    String? equipment,
    String? bodyPart,
  }) async {
    try {
      final allExercises = await getAllExercises();

      // Filter exercises based on provided parameters
      final filteredExercises = allExercises.where((exercise) {
        bool matches = true;

        if (target != null && target.isNotEmpty) {
          matches = matches &&
              (exercise['target']?.toString().toLowerCase() ==
                      target.toLowerCase() ||
                  exercise['bodyPart']?.toString().toLowerCase() ==
                      target.toLowerCase());
        }

        if (equipment != null && equipment.isNotEmpty) {
          matches = matches &&
              exercise['equipment']?.toString().toLowerCase() ==
                  equipment.toLowerCase();
        }

        if (bodyPart != null && bodyPart.isNotEmpty) {
          matches = matches &&
              exercise['bodyPart']?.toString().toLowerCase() ==
                  bodyPart.toLowerCase();
        }

        return matches;
      }).toList();

      return filteredExercises.map((json) => _parseExercise(json)).toList();
    } catch (e) {
      print('Error fetching filtered exercises: $e');
      return [];
    }
  }

  // Get exercise details by name
  Future<Map<String, dynamic>> getExerciseDetails(String exerciseName) async {
    try {
      // First try to get exercise from cache
      if (_cachedExercises != null) {
        final exercise = _cachedExercises!.firstWhere(
          (e) =>
              e['name'].toString().toLowerCase() == exerciseName.toLowerCase(),
          orElse: () => throw Exception('Exercise not found in cache'),
        );
        return exercise;
      }

      // If not in cache, try to get it directly from the API
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/name/$exerciseName'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else {
          throw Exception('Exercise not found: $exerciseName');
        }
      } else {
        print(
            'Failed to load exercise details: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to load exercise details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercise details: $e');
      throw Exception('Error fetching exercise details: $e');
    }
  }

  // Parse exercise data from JSON
  Exercise _parseExercise(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      sets: '3', // Default value, will be overridden by WorkoutService
      reps: '12', // Default value, will be overridden by WorkoutService
      rest: '60', // Default value, will be overridden by WorkoutService
      icon: _getExerciseIcon(json['target'] ?? json['bodyPart'] ?? ''),
      musclesWorked: [
        json['target']?.toString() ?? '',
        json['bodyPart']?.toString() ?? '',
        ...(json['secondaryMuscles'] ?? []).map((e) => e.toString()),
      ].where((muscle) => muscle.isNotEmpty).toList().cast<String>(),
      instructions: json['instructions'] != null
          ? (json['instructions'] is List
              ? List<String>.from(json['instructions'])
              : json['instructions'].toString().split('\n'))
          : [],
      gifUrl: json['gifUrl'] ?? '',
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
