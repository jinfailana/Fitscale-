import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutHistory {
  final String id;
  final String workoutName;
  final String exerciseName;
  final DateTime date;
  final int setsCompleted;
  final int totalSets;
  final int repsPerSet;
  final String status; // 'completed' or 'in_progress'
  final int duration; // in minutes
  final List<String> musclesWorked;
  final String notes;
  final double weight; // Weight used for the exercise (if applicable)
  final double caloriesBurned; // Estimated calories burned
  final Map<String, dynamic>
      exerciseDetails; // Detailed tracking of each set (reps, weight, etc.)
  final String difficulty; // User-rated difficulty of the workout
  final int restBetweenSets; // Rest time between sets in seconds
  final double progress;
  final String goal;

  WorkoutHistory({
    required this.id,
    required this.workoutName,
    required this.exerciseName,
    required this.date,
    required this.setsCompleted,
    required this.totalSets,
    required this.repsPerSet,
    required this.status,
    required this.duration,
    required this.musclesWorked,
    required this.notes,
    required this.weight,
    required this.caloriesBurned,
    required this.exerciseDetails,
    required this.difficulty,
    required this.restBetweenSets,
    this.progress = 0.0,
    this.goal = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutName': workoutName,
      'exerciseName': exerciseName,
      'date': date.toIso8601String(),
      'setsCompleted': setsCompleted,
      'totalSets': totalSets,
      'repsPerSet': repsPerSet,
      'status': status,
      'duration': duration,
      'musclesWorked': musclesWorked,
      'notes': notes,
      'weight': weight,
      'caloriesBurned': caloriesBurned,
      'exerciseDetails': exerciseDetails,
      'difficulty': difficulty,
      'restBetweenSets': restBetweenSets,
      'progress': progress,
      'goal': goal,
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: map['id'] ?? '',
      workoutName: map['workoutName'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      date: DateTime.tryParse(map['date']) ?? DateTime.now(),
      setsCompleted: map['setsCompleted'] ?? 0,
      totalSets: map['totalSets'] ?? 0,
      repsPerSet: map['repsPerSet'] ?? 0,
      status: map['status'] ?? 'in_progress',
      duration: map['duration'] ?? 0,
      musclesWorked: List<String>.from(map['musclesWorked'] ?? []),
      notes: map['notes'] ?? '',
      weight: (map['weight'] ?? 0.0).toDouble(),
      caloriesBurned: (map['caloriesBurned'] ?? 0.0).toDouble(),
      exerciseDetails: Map<String, dynamic>.from(map['exerciseDetails'] ?? {}),
      difficulty: map['difficulty'] ?? 'medium',
      restBetweenSets: map['restBetweenSets'] ?? 60,
      progress: (map['progress'] ?? 0.0).toDouble(),
      goal: map['goal'] ?? '',
    );
  }

  @override
  String toString() {
    return 'WorkoutHistory(id: $id, workoutName: $workoutName, exerciseName: $exerciseName, date: $date, setsCompleted: $setsCompleted, totalSets: $totalSets, repsPerSet: $repsPerSet, status: $status, duration: $duration, musclesWorked: $musclesWorked, notes: $notes, weight: $weight, caloriesBurned: $caloriesBurned, difficulty: $difficulty, progress: $progress, goal: $goal)';
  }

  double get progressPercentage => (setsCompleted / totalSets) * 100;
  bool get isCompleted => status == 'completed';

  // New helper methods
  double get volumePerSet => weight * repsPerSet;
  double get totalVolume => volumePerSet * setsCompleted;

  // Calculate estimated one rep max using Brzycki formula
  double get estimatedOneRepMax {
    if (weight <= 0 || repsPerSet <= 0) return 0;
    return weight * (36 / (37 - repsPerSet));
  }

  // Get a color based on the difficulty rating
  String get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '#4CAF50'; // Green
      case 'medium':
        return '#FFC107'; // Amber
      case 'hard':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
