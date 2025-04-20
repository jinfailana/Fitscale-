import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepGoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch recommended goals based on BMI
  Future<List<Map<String, dynamic>>> getRecommendedGoals(double bmi, int age) async {
    try {
      // Try to get base goals from Firebase
      final goalsDoc = await _firestore.collection('step_goals').doc('base_goals').get();
      
      // If base goals don't exist, create them
      if (!goalsDoc.exists) {
        await _initializeBaseGoals();
        return _getDefaultGoals();
      }

      Map<String, dynamic> baseGoals = goalsDoc.data()!;
      String bmiCategory = _getBMICategory(bmi);
      
      // Try to get BMI adjustments
      final bmiGoalsDoc = await _firestore
          .collection('step_goals')
          .doc('bmi_adjustments')
          .collection(bmiCategory)
          .doc('adjustments')
          .get();

      // If BMI adjustments don't exist, create them
      if (!bmiGoalsDoc.exists) {
        await _initializeBMIAdjustments();
      }

      Map<String, dynamic> bmiAdjustments = bmiGoalsDoc.data() ?? {};
      double ageMultiplier = _getAgeMultiplier(age);

      List<Map<String, dynamic>> finalGoals = [];
      baseGoals.forEach((title, baseSteps) {
        int adjustedSteps = ((baseSteps as int) * 
            (bmiAdjustments[title] ?? 1.0) * 
            ageMultiplier).round();
        adjustedSteps = (adjustedSteps / 500).round() * 500;
        
        finalGoals.add({
          'title': title,
          'steps': adjustedSteps,
        });
      });

      return finalGoals;
    } catch (e) {
      print('Error getting recommended goals: $e');
      return _getDefaultGoals();
    }
  }

  Future<void> _initializeBaseGoals() async {
    try {
      await _firestore.collection('step_goals').doc('base_goals').set({
        'become_active': 3000,
        'keep_fit': 7000,
        'boost_metabolism': 10000,
        'lose_weight': 12000,
      });
    } catch (e) {
      print('Error initializing base goals: $e');
    }
  }

  Future<void> _initializeBMIAdjustments() async {
    try {
      final bmiCategories = ['underweight', 'normal', 'overweight', 'obese'];
      final adjustments = {
        'underweight': {
          'become_active': 1.0,
          'keep_fit': 0.9,
          'boost_metabolism': 0.8,
          'lose_weight': 0.7,
        },
        'normal': {
          'become_active': 1.0,
          'keep_fit': 1.0,
          'boost_metabolism': 1.0,
          'lose_weight': 1.0,
        },
        'overweight': {
          'become_active': 1.2,
          'keep_fit': 1.1,
          'boost_metabolism': 1.1,
          'lose_weight': 1.2,
        },
        'obese': {
          'become_active': 0.8,
          'keep_fit': 0.9,
          'boost_metabolism': 0.9,
          'lose_weight': 1.0,
        },
      };

      for (var category in bmiCategories) {
        await _firestore
            .collection('step_goals')
            .doc('bmi_adjustments')
            .collection(category)
            .doc('adjustments')
            .set(adjustments[category]!);
      }
    } catch (e) {
      print('Error initializing BMI adjustments: $e');
    }
  }

  // Save user's selected goal
  Future<void> saveUserGoal(int steps) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(userId).update({
        'step_goal': steps,
        'last_goal_set_date': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving user goal: $e');
      rethrow;
    }
  }

  // Get user's current goal
  Future<int> getUserGoal() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['step_goal'] ?? 650;
    } catch (e) {
      print('Error getting user goal: $e');
      return 650; // Default goal
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 24.9) return 'normal';
    if (bmi < 29.9) return 'overweight';
    return 'obese';
  }

  double _getAgeMultiplier(int age) {
    if (age > 70) return 0.7;
    if (age > 60) return 0.8;
    if (age > 50) return 0.9;
    if (age < 18) return 1.2;
    return 1.0;
  }

  List<Map<String, dynamic>> _getDefaultGoals() {
    return [
      {'title': 'Become active', 'steps': 3000},
      {'title': 'Keep fit', 'steps': 7000},
      {'title': 'Boost metabolism', 'steps': 10000},
      {'title': 'Lose weight', 'steps': 12000},
    ];
  }
} 