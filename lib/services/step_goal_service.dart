import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getRecommendedStepGoals(double bmi) async {
    // Define BMI categories and their corresponding step goals
    final goals = _getStepGoalsForBMI(bmi);
    return goals;
  }

  List<Map<String, dynamic>> _getStepGoalsForBMI(double bmi) {
    if (bmi < 18.5) {
      // Underweight
      return [
        {'steps': 6000, 'description': 'Keep Fit'},
        {'steps': 7000, 'description': 'Become Active'},
        {'steps': 6500, 'description': 'Boost Metabolism'},
        // Not advised for weight loss
      ];
    } else if (bmi >= 18.5 && bmi < 25) {
      // Normal (Healthy)
      return [
        {'steps': 7000, 'description': 'Keep Fit'},
        {'steps': 8000, 'description': 'Lose Weight'},
        {'steps': 8500, 'description': 'Become Active'},
        {'steps': 7500, 'description': 'Boost Metabolism'},
      ];
    } else if (bmi >= 25 && bmi < 30) {
      // Overweight
      return [
        {'steps': 8000, 'description': 'Keep Fit'},
        {'steps': 10000, 'description': 'Lose Weight'},
        {'steps': 9500, 'description': 'Become Active'},
        {'steps': 8500, 'description': 'Boost Metabolism'},
      ];
    } else if (bmi >= 30 && bmi < 35) {
      // Obese Class I
      return [
        {'steps': 8000, 'description': 'Keep Fit'},
        {'steps': 11000, 'description': 'Lose Weight'},
        {'steps': 10000, 'description': 'Become Active'},
        {'steps': 9000, 'description': 'Boost Metabolism'},
      ];
    } else {
      // Obese Class II & III (BMI >= 35)
      return [
        {'steps': 7000, 'description': 'Keep Fit'},
        {'steps': 12000, 'description': 'Lose Weight'},
        {'steps': 10500, 'description': 'Become Active'},
        {'steps': 9000, 'description': 'Boost Metabolism'},
      ];
    }
  }

  // Get the last saved step count for today
  Future<int> getLastSavedStepCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data != null) {
        final lastUpdateDate = data['date'] as Timestamp?;
        if (lastUpdateDate != null) {
          final lastDate = lastUpdateDate.toDate();
          final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

          // If last update was today, return the saved steps
          if (lastDay.isAtSameMomentAs(today)) {
            return data['current_steps'] ?? 0;
          }
        }
      }
      return 0;
    } catch (e) {
      print('Error getting last saved step count: $e');
      return 0;
    }
  }

  // Save current step count
  Future<void> saveStepCount(int steps) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await _firestore.collection('users').doc(userId).update({
        'current_steps': steps,
        'last_updated': FieldValue.serverTimestamp(),
        'date': Timestamp.fromDate(today),
      });
    } catch (e) {
      print('Error saving step count: $e');
    }
  }

  // More accurate step calibration based on multiple samples
  Future<double> calculateCalibrationFactor() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 1.0;

      // Get the last 5 step samples from Firestore
      final samples = await _firestore
          .collection('step_samples')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (samples.docs.isEmpty) return 1.0;

      double totalRatio = 0;
      int validSamples = 0;

      for (var sample in samples.docs) {
        final data = sample.data();
        final actualSteps = data['actual_steps'] as int;
        final recordedSteps = data['recorded_steps'] as int;

        if (recordedSteps > 0) {
          totalRatio += actualSteps / recordedSteps;
          validSamples++;
        }
      }

      if (validSamples == 0) return 1.0;
      return totalRatio / validSamples;
    } catch (e) {
      print('Error calculating calibration factor: $e');
      return 1.0;
    }
  }

  // Save a step sample for calibration
  Future<void> saveStepSample(int actualSteps, int recordedSteps) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('step_samples').add({
        'user_id': userId,
        'actual_steps': actualSteps,
        'recorded_steps': recordedSteps,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Recalculate and update calibration factor
      final newFactor = await calculateCalibrationFactor();
      await _firestore.collection('users').doc(userId).update({
        'step_calibration_factor': newFactor,
      });
    } catch (e) {
      print('Error saving step sample: $e');
    }
  }
}
