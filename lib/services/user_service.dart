import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update user gender
  Future<void> updateGender(String userId, String gender) async {
    await _firestore.collection('users').doc(userId).update({
      'gender': gender,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update user goal
  Future<void> updateGoal(String userId, String goal) async {
    await _firestore.collection('users').doc(userId).update({
      'goal': goal,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update user metrics (birth year, height, weight)
  Future<void> updateMetrics(
    String userId, {
    int? birthYear,
    double? height,
    double? weight,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (birthYear != null) updates['birthYear'] = birthYear;
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;
    updates['updatedAt'] = DateTime.now().toIso8601String();

    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Update activity level
  Future<void> updateActivityLevel(String userId, String activityLevel) async {
    await _firestore.collection('users').doc(userId).update({
      'activityLevel': activityLevel,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update workplace
  Future<void> updateWorkPlace(String userId, String workPlace) async {
    await _firestore.collection('users').doc(userId).update({
      'workPlace': workPlace,
      'setupCompleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update preferred workout
  Future<void> updatePrefWorkout(String userId, List<String> prefWorkouts) async {
    await _firestore.collection('users').doc(userId).update({
      'preferredWorkouts': prefWorkouts,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update workout place
  Future<void> updateWorkoutPlace(String userId, String workoutPlace) async {
    await _firestore.collection('users').doc(userId).update({
      'workoutPlace': workoutPlace,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update gym equipment
  Future<void> updateGymEquipment(String userId, List<String> equipment) async {
    await _firestore.collection('users').doc(userId).update({
      'gymEquipment': equipment,
      'setupCompleted': true, // Mark setup as complete on final step
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }
} 