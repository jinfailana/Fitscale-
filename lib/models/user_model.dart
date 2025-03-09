import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String email;
  final String? gender;
  final String? goal;
  final int? age;
  final double? weight;
  final double? height;
  final String? activityLevel;
  final String? workPlace;
  final bool setupCompleted;
  final String currentSetupStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.gender,
    this.goal,
    this.age,
    this.weight,
    this.height,
    this.activityLevel,
    this.workPlace,
    this.setupCompleted = false,
    this.currentSetupStep = 'registered',
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? gender,
    String? goal,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? workPlace,
    bool? setupCompleted,
    String? currentSetupStep,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      workPlace: workPlace ?? this.workPlace,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      currentSetupStep: currentSetupStep ?? this.currentSetupStep,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'gender': gender,
      'goal': goal,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'workPlace': workPlace,
      'setupCompleted': setupCompleted,
      'currentSetupStep': currentSetupStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      gender: map['gender'],
      goal: map['goal'],
      age: map['age'],
      height: map['height'],
      weight: map['weight'],
      activityLevel: map['activityLevel'],
      workPlace: map['workPlace'],
      setupCompleted: map['setupCompleted'] ?? false,
      currentSetupStep: map['currentSetupStep'] ?? 'registered',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  bool get isSetupComplete {
    return gender != null &&
        goal != null &&
        age != null &&
        height != null &&
        weight != null &&
        activityLevel != null &&
        workPlace != null;
  }

  String getNextSetupStep() {
    if (gender == null) return 'gender';
    if (goal == null) return 'goal';
    if (age == null || height == null || weight == null) return 'metrics';
    if (activityLevel == null) return 'activity';
    if (workPlace == null) return 'workplace';
    return 'completed';
  }

  double? get bmi {
    if (height == null || weight == null) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  Map<String, dynamic>? get bmiCategory {
    if (bmi == null) return null;

    if (bmi! < 18.5) {
      return {
        'category': 'Underweight',
        'description':
            'You are below the normal weight range. Consider consulting a healthcare provider for guidance on healthy weight gain.',
        'color': Colors.blue,
      };
    } else if (bmi! < 25) {
      return {
        'category': 'Normal Weight',
        'description':
            'Your weight is within the healthy range. Maintain your current lifestyle!',
        'color': Colors.green,
      };
    } else if (bmi! < 30) {
      return {
        'category': 'Overweight',
        'description':
            'You are above the normal weight range. Consider increasing physical activity and monitoring calorie intake.',
        'color': Colors.orange,
      };
    } else {
      return {
        'category': 'Obese',
        'description':
            'You are significantly above the normal weight range. Please consult a healthcare provider for guidance.',
        'color': Colors.red,
      };
    }
  }

  String? get bmiFormatted {
    if (bmi == null) return null;
    return bmi!.toStringAsFixed(1);
  }

  double? get dailyCalorieNeeds {
    if (weight == null || height == null || age == null || gender == null) {
      return null;
    }

    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight! + 6.25 * height! - 5 * age! + 5;
    } else {
      bmr = 10 * weight! + 6.25 * height! - 5 * age! - 161;
    }

    double activityFactor = 1.2;
    switch (activityLevel) {
      case 'Lightly Active':
        activityFactor = 1.375;
        break;
      case 'Moderately Active':
        activityFactor = 1.55;
        break;
      case 'Very Active':
        activityFactor = 1.725;
        break;
      case 'Extra Active':
        activityFactor = 1.9;
        break;
    }

    return bmr * activityFactor;
  }
}
