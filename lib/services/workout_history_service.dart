import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_history.dart';
import '../models/workout_plan.dart';

class WorkoutHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String userId;

  WorkoutHistoryService({required this.userId});

  Future<void> saveWorkoutHistory(WorkoutHistory workoutHistory) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .doc(workoutHistory.id)
            .set(workoutHistory.toMap());
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

        final workouts = snapshot.docs
            .map((doc) {
              try {
                return WorkoutHistory.fromMap(doc.data());
              } catch (e) {
                print('Error parsing workout history document: $e');
                return null;
              }
            })
            .where((workout) => workout != null)
            .cast<WorkoutHistory>()
            .toList();

        print('Fetched ${workouts.length} workout history items');
        return workouts;
      }
      return [];
    } catch (e) {
      print('Error fetching workout history: $e');
      print('Stack trace: ${StackTrace.current}');
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

  Future<void> logExercise(
    WorkoutPlan workout,
    Exercise exercise,
    int completedSets,
    String notes,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final exerciseId =
          '${workout.name}_${exercise.name}_${now.millisecondsSinceEpoch}';

      // Create workout history entry
      final workoutHistory = WorkoutHistory(
        id: exerciseId,
        workoutName: workout.name,
        exerciseName: exercise.name,
        date: now,
        setsCompleted: completedSets,
        totalSets: int.parse(exercise.sets),
        repsPerSet: int.parse(exercise.reps),
        status: completedSets >= int.parse(exercise.sets)
            ? 'completed'
            : 'in_progress',
        duration: 0, // You can add actual duration if tracked
        musclesWorked: exercise.musclesWorked,
        notes: notes,
      );

      // Save to workout_history collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .doc(exerciseId)
          .set(workoutHistory.toMap());

      // Create exercise history document
      final exerciseHistoryData = {
        'exerciseId': exerciseId,
        'exerciseName': exercise.name,
        'workoutTitle': workout.name,
        'setsCompleted': completedSets,
        'totalSets': exercise.sets,
        'reps': exercise.reps,
        'musclesWorked': exercise.musclesWorked,
        'notes': notes,
        'timestamp': now.toIso8601String(),
        'date': Timestamp.fromDate(now),
        'day': now.day,
        'month': now.month,
        'year': now.year,
        'userId': user.uid,
        'volume': completedSets * (int.tryParse(exercise.reps) ?? 0),
        'status': completedSets >= int.parse(exercise.sets)
            ? 'completed'
            : 'in_progress',
      };

      // Save to exerciseHistory collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exerciseHistory')
          .doc(exerciseId)
          .set(exerciseHistoryData);

      // Update recent workouts
      final recentRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recent_workouts')
          .doc(workout.name);

      final recentData = {
        'workoutTitle': workout.name,
        'lastCompleted': now.toIso8601String(),
        'lastExercise': {
          'exerciseId': exerciseId,
          'exerciseName': exercise.name,
          'setsCompleted': completedSets,
          'totalSets': exercise.sets,
          'timestamp': now.toIso8601String(),
          'date': Timestamp.fromDate(now),
        }
      };

      await recentRef.set(recentData, SetOptions(merge: true));

      // Update workout progress
      final exerciseData = {
        'exercises': {
          exercise.name: {
            'exerciseId': exerciseId,
            'name': exercise.name,
            'setsCompleted': completedSets,
            'sets': exercise.sets,
            'isCompleted': completedSets >= int.parse(exercise.sets),
            'lastCompleted': now.toIso8601String(),
            'musclesWorked': exercise.musclesWorked,
            'reps': exercise.reps,
            'instructions': exercise.instructions,
            'imageHtml': exercise.imageHtml,
            'rest': exercise.rest,
            'iconCode': exercise.icon.codePoint,
          }
        },
        'lastUpdated': now.toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workout.name)
          .set(exerciseData, SetOptions(merge: true));
    } catch (e) {
      print('Error logging exercise: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExerciseHistoryForChart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'hasData': false};
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exerciseHistory')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'hasData': false};
      }

      // Group exercises by day
      final Map<int, int> dailyVolume = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final day = data['day'] as int;
        final volume = data['volume'] as int;
        dailyVolume[day] = (dailyVolume[day] ?? 0) + volume;
      }

      // Convert to chart data format
      final List<Map<String, dynamic>> chartData = dailyVolume.entries
          .map((e) => {
                'day': e.key,
                'volume': e.value,
              })
          .toList();

      return {
        'hasData': true,
        'chartData': chartData,
      };
    } catch (e) {
      print('Error getting exercise history for chart: $e');
      return {'hasData': false};
    }
  }

  Future<bool> isWorkoutInUserList(String workoutName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final workoutDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workoutName)
          .get();

      if (!workoutDoc.exists) return false;

      final data = workoutDoc.data();
      return data?['isInMyWorkouts'] as bool? ?? false;
    } catch (e) {
      print('Error checking workout existence: $e');
      return false;
    }
  }

  Future<void> addWorkoutToUserList(WorkoutPlan workout) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      // Create a map of exercises for easier access
      final exercisesMap = {
        for (var exercise in workout.exercises)
          exercise.name: {
            'name': exercise.name,
            'sets': exercise.sets,
            'reps': exercise.reps,
            'rest': exercise.rest,
            'musclesWorked': exercise.musclesWorked,
            'instructions': exercise.instructions,
            'imageHtml': exercise.imageHtml,
            'iconCode': exercise.icon.codePoint,
            'setsCompleted': 0,
            'isCompleted': false,
          }
      };

      // Use set with merge to ensure the workout stays in the list
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workout.name)
          .set({
        'name': workout.name,
        'description': workout.description,
        'icon': workout.icon.codePoint,
        'exercises': exercisesMap,
        'addedAt': now.toIso8601String(),
        'lastUpdated': now.toIso8601String(),
        'isInMyWorkouts': true, // Add flag to track workout status
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding workout: $e');
      rethrow;
    }
  }

  Future<void> updateExerciseProgress(
    String workoutName,
    String exerciseName,
    int setsCompleted,
    bool isCompleted,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final workoutRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workoutName);

      final now = DateTime.now();

      // Update the specific exercise in the exercises map
      await workoutRef.set({
        'exercises': {
          exerciseName: {
            'setsCompleted': setsCompleted,
            'isCompleted': isCompleted,
            'lastCompleted': now.toIso8601String(),
          }
        },
        'lastUpdated': now.toIso8601String(),
      }, SetOptions(merge: true));

      // Log the progress update
      final exerciseId =
          '${workoutName}_${exerciseName}_${now.millisecondsSinceEpoch}';
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exerciseHistory')
          .doc(exerciseId)
          .set({
        'exerciseId': exerciseId,
        'workoutName': workoutName,
        'exerciseName': exerciseName,
        'setsCompleted': setsCompleted,
        'timestamp': now.toIso8601String(),
        'isCompleted': isCompleted,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating exercise progress: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Add a new workout history entry
  Future<void> addWorkoutHistory(WorkoutHistory workoutHistory) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_history')
          .doc(workoutHistory.id)
          .set(workoutHistory.toMap());
    } catch (e) {
      print('Error adding workout history: $e');
      rethrow;
    }
  }

  // Get all workout history entries
  Stream<List<WorkoutHistory>> getWorkoutHistoryStream() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workout_history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkoutHistory.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get recent workouts (last 7 days)
  Stream<List<WorkoutHistory>> getRecentWorkouts() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workout_history')
        .where('date', isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkoutHistory.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Update a workout history entry
  Future<void> updateWorkoutHistory(WorkoutHistory workoutHistory) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_history')
          .doc(workoutHistory.id)
          .update(workoutHistory.toMap());
    } catch (e) {
      print('Error updating workout history: $e');
      rethrow;
    }
  }

  // Delete a workout history entry
  Future<void> deleteWorkoutHistory(String workoutHistoryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_history')
          .doc(workoutHistoryId)
          .delete();
    } catch (e) {
      print('Error deleting workout history: $e');
      rethrow;
    }
  }

  // New method to get workout analytics
  Future<Map<String, dynamic>> getWorkoutAnalytics({int days = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final DateTime startDate =
            DateTime.now().subtract(Duration(days: days));

        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .where('date', isGreaterThan: startDate.toIso8601String())
            .get();

        final workouts = querySnapshot.docs
            .map((doc) => WorkoutHistory.fromMap(doc.data()))
            .toList();

        // Calculate analytics
        double totalCaloriesBurned = 0;
        double totalVolume = 0;
        Map<String, int> muscleGroupFrequency = {};
        Map<String, double> averageWeightByExercise = {};
        Map<String, List<double>> progressByExercise = {};

        for (var workout in workouts) {
          totalCaloriesBurned += workout.caloriesBurned;
          totalVolume += workout.totalVolume;

          // Track muscle group frequency
          for (var muscle in workout.musclesWorked) {
            muscleGroupFrequency[muscle] =
                (muscleGroupFrequency[muscle] ?? 0) + 1;
          }

          // Track progress by exercise
          if (!progressByExercise.containsKey(workout.exerciseName)) {
            progressByExercise[workout.exerciseName] = [];
          }
          progressByExercise[workout.exerciseName]!.add(workout.weight);

          // Calculate average weight per exercise
          if (!averageWeightByExercise.containsKey(workout.exerciseName)) {
            averageWeightByExercise[workout.exerciseName] = 0;
          }
          averageWeightByExercise[workout.exerciseName] =
              (averageWeightByExercise[workout.exerciseName]! +
                      workout.weight) /
                  2;
        }

        return {
          'totalWorkouts': workouts.length,
          'totalCaloriesBurned': totalCaloriesBurned,
          'totalVolume': totalVolume,
          'muscleGroupFrequency': muscleGroupFrequency,
          'averageWeightByExercise': averageWeightByExercise,
          'progressByExercise': progressByExercise,
          'completionRate':
              workouts.where((w) => w.isCompleted).length / workouts.length,
        };
      }
      return {};
    } catch (e) {
      print('Error getting workout analytics: $e');
      rethrow;
    }
  }

  // New method to get exercise recommendations based on history
  Future<List<String>> getExerciseRecommendations() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .orderBy('date', descending: true)
            .limit(30)
            .get();

        final workouts = querySnapshot.docs
            .map((doc) => WorkoutHistory.fromMap(doc.data()))
            .toList();

        // Analyze muscle groups that need attention
        Map<String, DateTime> lastWorkedDate = {};
        for (var workout in workouts) {
          for (var muscle in workout.musclesWorked) {
            if (!lastWorkedDate.containsKey(muscle) ||
                workout.date.isAfter(lastWorkedDate[muscle]!)) {
              lastWorkedDate[muscle] = workout.date;
            }
          }
        }

        // Find muscles that haven't been worked in a while (>7 days)
        List<String> needsAttention = lastWorkedDate.entries
            .where((entry) => entry.value
                .isBefore(DateTime.now().subtract(Duration(days: 7))))
            .map((entry) => entry.key)
            .toList();

        return needsAttention;
      }
      return [];
    } catch (e) {
      print('Error getting exercise recommendations: $e');
      rethrow;
    }
  }
}
