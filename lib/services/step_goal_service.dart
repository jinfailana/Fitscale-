import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getRecommendedStepGoals(double bmi) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Fetch step goals from Firebase, scoped to user's BMI range
      final QuerySnapshot stepGoalsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
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
              'user_id': user.uid, // Add user ID for reference
            };
          })
          .toList();

      // If no personalized goals exist, create default ones for this user
      if (goals.isEmpty) {
        await _createDefaultGoalsForUser(user.uid, bmi);
        return await getRecommendedStepGoals(bmi); // Retry after creating defaults
      }

      return goals;
    } catch (e) {
      print('Error fetching step goals: $e');
      return getDefaultStepGoals();
    }
  }

  Future<void> _createDefaultGoalsForUser(String userId, double bmi) async {
    final defaultGoals = getDefaultStepGoals();
    final batch = _firestore.batch();

    for (var goal in defaultGoals) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('step_goals')
          .doc();

      batch.set(docRef, {
        ...goal,
        'user_id': userId,
        'min_bmi': bmi - 2, // Create a reasonable BMI range
        'max_bmi': bmi + 2,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
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