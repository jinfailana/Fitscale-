import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_history.dart';

class WorkoutHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveWorkoutHistory(WorkoutHistory history) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .doc(history.id)
            .set(history.toMap());
      }
    } catch (e) {
      print('Error saving workout history: $e');
      rethrow;
    }
  }

  Future<List<WorkoutHistory>> getWorkoutHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => WorkoutHistory.fromMap(doc.data()))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching workout history: $e');
      return [];
    }
  }

  Future<List<WorkoutHistory>> getWorkoutHistoryByDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => WorkoutHistory.fromMap(doc.data()))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching workout history by date: $e');
      return [];
    }
  }

  Future<void> updateWorkoutStatus(String historyId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .doc(historyId)
            .update({'status': status});
      }
    } catch (e) {
      print('Error updating workout status: $e');
      rethrow;
    }
  }
} 