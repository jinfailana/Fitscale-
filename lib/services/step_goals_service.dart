import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepGoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch recommended goals based on BMI
  Future<List<Map<String, dynamic>>> getRecommendedGoals(double bmi, int age) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Get user's personal goals collection
      final userGoalsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('personal_goals')
          .get();

      // If user doesn't have personal goals, create them
      if (!userGoalsDoc.exists) {
        await _initializeUserGoals(user.uid, bmi, age);
        return _getDefaultGoals(user.uid);
      }

      Map<String, dynamic> baseGoals = userGoalsDoc.data()!;
      String bmiCategory = _getBMICategory(bmi);
      
      // Get user's BMI adjustments
      final bmiGoalsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('bmi_adjustments')
          .get();

      // If BMI adjustments don't exist, create them
      if (!bmiGoalsDoc.exists) {
        await _initializeUserBMIAdjustments(user.uid, bmiCategory);
      }

      Map<String, dynamic> bmiAdjustments = bmiGoalsDoc.data() ?? {};
      double ageMultiplier = _getAgeMultiplier(age);

      List<Map<String, dynamic>> finalGoals = [];
      baseGoals.forEach((title, baseSteps) {
        if (title != 'user_id') { // Skip the user_id field
          int adjustedSteps = ((baseSteps as int) * 
              (bmiAdjustments[title] ?? 1.0) * 
              ageMultiplier).round();
          adjustedSteps = (adjustedSteps / 500).round() * 500;
          
          finalGoals.add({
            'title': title,
            'steps': adjustedSteps,
            'user_id': user.uid,
          });
        }
      });

      return finalGoals;
    } catch (e) {
      print('Error getting recommended goals: $e');
      return _getDefaultGoals(_auth.currentUser?.uid);
    }
  }

  Future<void> _initializeUserGoals(String userId, double bmi, int age) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc('personal_goals')
          .set({
        'become_active': 3000,
        'keep_fit': 7000,
        'boost_metabolism': 10000,
        'lose_weight': 12000,
        'user_id': userId,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error initializing user goals: $e');
    }
  }

  Future<void> _initializeUserBMIAdjustments(String userId, String bmiCategory) async {
    try {
      final adjustments = {
        'become_active': 1.0,
        'keep_fit': 1.0,
        'boost_metabolism': 1.0,
        'lose_weight': 1.0,
        'user_id': userId,
        'bmi_category': bmiCategory,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc('bmi_adjustments')
          .set(adjustments);
    } catch (e) {
      print('Error initializing user BMI adjustments: $e');
    }
  }

  // Save user's selected goal
  Future<void> saveUserGoal(int steps) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(userId).update({
        'step_goal': steps,
        'last_goal_set_date': FieldValue.serverTimestamp(),
        'user_id': userId,
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
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  double _getAgeMultiplier(int age) {
    if (age < 30) return 1.2;
    if (age < 50) return 1.0;
    if (age < 70) return 0.8;
    return 0.6;
  }

  List<Map<String, dynamic>> _getDefaultGoals(String? userId) {
    return [
      {'title': 'become_active', 'steps': 3000, 'user_id': userId},
      {'title': 'keep_fit', 'steps': 7000, 'user_id': userId},
      {'title': 'boost_metabolism', 'steps': 10000, 'user_id': userId},
      {'title': 'lose_weight', 'steps': 12000, 'user_id': userId},
    ];
  }
} 