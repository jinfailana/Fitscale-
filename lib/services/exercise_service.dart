import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseService {
  static const String _baseUrl =
      'https://exercise-db-fitness-workout-gym.p.rapidapi.com';
  static const String _apiKey =
      '3d093f5b58mshd807261fbdb710ap16b0a8jsn1c452bc6f2a5';

  Future<Map<String, dynamic>> getExerciseDetails(String exerciseName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/name/$exerciseName'),
        headers: {
          'x-rapidapi-host': 'exercise-db-fitness-workout-gym.p.rapidapi.com',
          'x-rapidapi-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching exercise details: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesByEquipment(
      String equipment) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/equipment/$equipment'),
        headers: {
          'x-rapidapi-host': 'exercise-db-fitness-workout-gym.p.rapidapi.com',
          'x-rapidapi-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching exercises by equipment: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesByTarget(String target) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/target/$target'),
        headers: {
          'x-rapidapi-host': 'exercise-db-fitness-workout-gym.p.rapidapi.com',
          'x-rapidapi-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching exercises by target: $e');
      return [];
    }
  }
}
