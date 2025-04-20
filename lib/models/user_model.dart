class UserModel {
  final String id;
  final String email;
  final String? gender;
  final String? goal;
  final int? age;
  final double? weight;
  final double? height;
  final String? activityLevel;
  final String? workoutPlace;
  final List<String>? preferredWorkouts;
  final List<String>? gymEquipment;
  final bool setupCompleted;
  final String currentSetupStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? expertiseLevel;
  final bool? hasEquipment;
  final String? prefWorkout;

  UserModel({
    required this.id,
    required this.email,
    this.gender,
    this.goal,
    this.age,
    this.weight,
    this.height,
    this.activityLevel,
    this.workoutPlace,
    this.preferredWorkouts,
    this.gymEquipment,
    this.setupCompleted = false,
    this.currentSetupStep = 'registered',
    required this.createdAt,
    required this.updatedAt,
    this.expertiseLevel,
    this.hasEquipment,
    this.prefWorkout,
  });

  UserModel copyWith({
    String? gender,
    String? goal,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? workoutPlace,
    List<String>? preferredWorkouts,
    List<String>? gymEquipment,
    bool? setupCompleted,
    String? currentSetupStep,
    String? expertiseLevel,
    bool? hasEquipment,
    String? prefWorkout,
  }) {
    return UserModel(
      id: id,
      email: email,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      workoutPlace: workoutPlace ?? this.workoutPlace,
      preferredWorkouts: preferredWorkouts ?? this.preferredWorkouts,
      gymEquipment: gymEquipment ?? this.gymEquipment,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      currentSetupStep: currentSetupStep ?? this.currentSetupStep,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expertiseLevel: expertiseLevel ?? this.expertiseLevel,
      hasEquipment: hasEquipment ?? this.hasEquipment,
      prefWorkout: prefWorkout ?? this.prefWorkout,
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
      'workoutPlace': workoutPlace,
      'preferredWorkouts': preferredWorkouts,
      'gymEquipment': gymEquipment,
      'setupCompleted': setupCompleted,
      'currentSetupStep': currentSetupStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expertiseLevel': expertiseLevel,
      'hasEquipment': hasEquipment,
      'prefWorkout': prefWorkout,
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
      workoutPlace: map['workoutPlace'],
      preferredWorkouts: map['preferredWorkouts'] != null
          ? List<String>.from(map['preferredWorkouts'])
          : null,
      gymEquipment: map['gymEquipment'] != null
          ? List<String>.from(map['gymEquipment'])
          : null,
      setupCompleted: map['setupCompleted'] ?? false,
      currentSetupStep: map['currentSetupStep'] ?? 'registered',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      expertiseLevel: map['expertiseLevel'],
      hasEquipment: map['hasEquipment'],
      prefWorkout: map['prefWorkout'],
    );
  }

  bool get isSetupComplete {
    return gender != null &&
        goal != null &&
        age != null &&
        height != null &&
        weight != null &&
        activityLevel != null &&
        workoutPlace != null;
  }

  String getNextSetupStep() {
    if (gender == null) return 'gender';
    if (goal == null) return 'goal';
    if (age == null || height == null || weight == null) return 'metrics';
    if (activityLevel == null) return 'activity';
    if (workoutPlace == null) return 'workplace';
    return 'completed';
  }

  double? get bmi {
    if (height == null || weight == null) return null;
    return weight! / ((height! / 100) * (height! / 100));
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
