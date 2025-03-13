import 'package:cloud_firestore/cloud_firestore.dart';

class StepGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getRecommendedStepGoals(double bmi) async {
    try {
      // Fetch step goals from Firebase
      final QuerySnapshot stepGoalsDoc = await _firestore
          .collection('step_goals')
          .orderBy('min_bmi')
          .get();

      // Find appropriate goals based on BMI
      final goals = stepGoalsDoc.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final minBmi = data['min_bmi'] as num;
            final maxBmi = data['max_bmi'] as num;
            return bmi >= minBmi && bmi <= maxBmi;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'steps': data['steps'],
              'description': data['description'],
            };
          })
          .toList();

      return goals.isEmpty ? getDefaultStepGoals() : goals;
    } catch (e) {
      print('Error fetching step goals: $e');
      return getDefaultStepGoals();
    }
  }

  List<Map<String, dynamic>> getDefaultStepGoals() {
    return [
      {'steps': 2500, 'description': 'Become active'},
      {'steps': 5000, 'description': 'Keep fit'},
      {'steps': 8000, 'description': 'Boost metabolism'},
      {'steps': 15000, 'description': 'Lose weight'},
    ];
  }
} 