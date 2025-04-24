import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get user's personal document
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Initialize user data if it doesn't exist
        final initialData = {
          'email': user.email,
          'current_steps': 0,
          'step_goal': 0,
          'calories_burned': 0.0,
          'distance_covered': 0.0,
          'last_updated': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'user_id': user.uid, // Add user ID for reference
        };
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(initialData, SetOptions(merge: true));
            
        return initialData;
      }

      return userDoc.data();
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Get user data by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first.data();
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Update user steps data with user-specific tracking
  Future<void> updateUserSteps(int steps, double calories, double distance) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Reference to user's personal document
      final userRef = _firestore.collection('users').doc(user.uid);
      
      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          transaction.set(userRef, {
            'email': user.email,
            'current_steps': steps,
            'calories_burned': calories,
            'distance_covered': distance,
            'last_updated': FieldValue.serverTimestamp(),
            'user_id': user.uid,
            'private': true, // Mark data as private
          });
        } else {
          // Update existing document
          transaction.update(userRef, {
            'current_steps': steps,
            'calories_burned': calories,
            'distance_covered': distance,
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Store in user's personal daily steps subcollection with privacy settings
      final dailyStepRef = userRef
          .collection('daily_steps')
          .doc(dateStr);

      await dailyStepRef.set({
        'steps': steps,
        'calories': calories,
        'distance': distance,
        'date': dateStr,
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'private': true, // Mark data as private
      }, SetOptions(merge: true));

    } catch (e) {
      print('Error updating user steps: $e');
      rethrow;
    }
  }

  // Get user's current step data - ensure privacy
  Future<Map<String, dynamic>> getCurrentStepData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        // Initialize user document if it doesn't exist with privacy settings
        final initialData = {
          'current_steps': 0,
          'calories_burned': 0.0,
          'distance_covered': 0.0,
          'step_goal': 0,
          'email': user.email,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': user.uid,
          'private': true, // Mark data as private
        };
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(initialData, SetOptions(merge: true));
            
        return initialData;
      }

      final data = userDoc.data()!;
      return {
        'current_steps': data['current_steps'] ?? 0,
        'calories_burned': data['calories_burned'] ?? 0.0,
        'distance_covered': data['distance_covered'] ?? 0.0,
        'step_goal': data['step_goal'] ?? 0,
        'user_id': data['user_id'] ?? user.uid,
      };
    } catch (e) {
      print('Error getting current step data: $e');
      return {
        'current_steps': 0,
        'calories_burned': 0.0,
        'distance_covered': 0.0,
        'step_goal': 0,
        'user_id': _auth.currentUser?.uid ?? '',
      };
    }
  }

  // Get user's step history with pagination - ensure privacy
  Future<List<Map<String, dynamic>>> getUserStepHistory({int limit = 7, DocumentSnapshot? startAfter}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Query user's personal daily_steps subcollection with strict user filtering
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_steps')
          .where('user_id', isEqualTo: user.uid) // Ensure only user's data is retrieved
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'],
          'steps': data['steps'],
          'calories': data['calories'],
          'distance': data['distance'],
          'timestamp': data['timestamp'],
          'user_id': data['user_id'],
        };
      }).toList();
    } catch (e) {
      print('Error getting user step history: $e');
      return [];
    }
  }

  // Set user's step goal
  Future<void> setStepGoal(int goal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Reference to user's personal document
      final userRef = _firestore.collection('users').doc(user.uid);

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          transaction.set(userRef, {
            'email': user.email,
            'step_goal': goal,
            'goal_set_date': FieldValue.serverTimestamp(),
            'user_id': user.uid,
            'created_at': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing document
          transaction.update(userRef, {
            'step_goal': goal,
            'goal_set_date': FieldValue.serverTimestamp(),
          });
        }
      });

      // Store goal history in user's personal collection
      await userRef.collection('goal_history').add({
        'goal': goal,
        'set_date': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      });

    } catch (e) {
      print('Error setting step goal: $e');
      rethrow;
    }
  }

  // Get user's step goal
  Future<int> getStepGoal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        // Initialize user document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'step_goal': 0,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': user.uid,
        }, SetOptions(merge: true));
        return 0;
      }
      
      return userDoc.data()?['step_goal'] ?? 0;
    } catch (e) {
      print('Error getting step goal: $e');
      return 0;
    }
  }
} 