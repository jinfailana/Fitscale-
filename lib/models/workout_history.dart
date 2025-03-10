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
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutName': workoutName,
      'exerciseName': exerciseName,
      'date': Timestamp.fromDate(date),
      'setsCompleted': setsCompleted,
      'totalSets': totalSets,
      'repsPerSet': repsPerSet,
      'status': status,
      'duration': duration,
      'musclesWorked': musclesWorked,
      'notes': notes,
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: map['id'] ?? '',
      workoutName: map['workoutName'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      setsCompleted: map['setsCompleted'] ?? 0,
      totalSets: map['totalSets'] ?? 0,
      repsPerSet: map['repsPerSet'] ?? 0,
      status: map['status'] ?? 'in_progress',
      duration: map['duration'] ?? 0,
      musclesWorked: List<String>.from(map['musclesWorked'] ?? []),
      notes: map['notes'] ?? '',
    );
  }

  double get progressPercentage => (setsCompleted / totalSets) * 100;
  bool get isCompleted => status == 'completed';
}
