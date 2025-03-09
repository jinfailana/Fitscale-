// lib/utils/recommendation_logic.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/workout_plan.dart';

List<WorkoutPlan> generateRecommendations(UserModel user) {
  List<WorkoutPlan> recommendations = [];

  // Determine workout intensity based on multiple factors
  String intensity = calculateIntensity(user);

  // Filter workouts based on available equipment and location
  bool hasGymAccess = user.workoutPlace?.toLowerCase() == "gym";
  List<String> availableEquipment = user.gymEquipment ?? [];

  // Calculate daily workout duration based on activity level and goals
  String workoutDuration = calculateWorkoutDuration(user);

  // Generate primary workouts based on user's goal
  if (user.goal?.toLowerCase() == "lose weight") {
    recommendations.addAll(getWeightLossWorkouts(
      intensity: intensity,
      hasGymAccess: hasGymAccess,
      equipment: availableEquipment,
      calorieTarget: user.dailyCalorieNeeds,
      duration: workoutDuration,
    ));
  } else if (user.goal?.toLowerCase() == "build muscle") {
    recommendations.addAll(getMuscleGainWorkouts(
      intensity: intensity,
      hasGymAccess: hasGymAccess,
      equipment: availableEquipment,
      duration: workoutDuration,
    ));
  } else if (user.goal?.toLowerCase() == "stay fit") {
    recommendations.addAll(getGeneralFitnessWorkouts(
      intensity: intensity,
      hasGymAccess: hasGymAccess,
      equipment: availableEquipment,
      duration: workoutDuration,
    ));
  }

  // Add complementary workouts based on preferred workout types
  if (user.preferredWorkouts?.contains("cardio") ?? false) {
    recommendations.add(getCardioWorkout(
      intensity: intensity,
      hasGymAccess: hasGymAccess,
      duration: workoutDuration,
    ));
  }

  if (user.preferredWorkouts?.contains("strength") ?? false) {
    recommendations.add(getStrengthWorkout(
      intensity: intensity,
      hasGymAccess: hasGymAccess,
      equipment: availableEquipment,
      duration: workoutDuration,
    ));
  }

  return recommendations;
}

String calculateIntensity(UserModel user) {
  // Calculate intensity based on multiple factors
  int intensityScore = 0;

  // Factor 1: Activity Level
  switch (user.activityLevel?.toLowerCase()) {
    case "sedentary":
      intensityScore += 1;
      break;
    case "lightly active":
      intensityScore += 2;
      break;
    case "moderately active":
      intensityScore += 3;
      break;
    case "very active":
      intensityScore += 4;
      break;
  }

  // Factor 2: Expertise Level
  switch (user.expertiseLevel?.toLowerCase()) {
    case "beginner":
      intensityScore += 1;
      break;
    case "intermediate":
      intensityScore += 2;
      break;
    case "advanced":
      intensityScore += 3;
      break;
  }

  // Calculate final intensity based on total score
  if (intensityScore <= 3) return "beginner";
  if (intensityScore <= 5) return "intermediate";
  return "advanced";
}

String calculateWorkoutDuration(UserModel user) {
  // Base duration on activity level and goal
  int baseDuration = 45; // Default 45 minutes

  // Adjust for activity level
  switch (user.activityLevel?.toLowerCase()) {
    case "sedentary":
      baseDuration = 30;
      break;
    case "very active":
      baseDuration = 60;
      break;
  }

  // Adjust for goal
  if (user.goal?.toLowerCase() == "lose weight") {
    baseDuration += 15; // Longer sessions for weight loss
  }

  return "$baseDuration min";
}

List<WorkoutPlan> getWeightLossWorkouts({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  double? calorieTarget,
  required String duration,
}) {
  if (hasGymAccess) {
    return [
      WorkoutPlan(
        name: "Fat Burning Program",
        description: "High-intensity gym workout focused on calorie burn",
        icon: Icons.local_fire_department,
        exercises: [
          Exercise(
            name: "Treadmill HIIT",
            sets: intensity == "beginner" ? "2" : "4",
            reps: "1 minute sprint, 2 minute walk",
            rest: intensity == "advanced" ? "45 sec" : "60 sec",
            icon: Icons.directions_run,
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Dumbbell Complex"
                : "Bodyweight Circuit",
            sets: "3",
            reps: getIntensityBasedReps(intensity),
            rest: "45 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: "Rowing Machine",
            sets: "3",
            reps: "500 meters",
            rest: "60 sec",
            icon: Icons.rowing,
          ),
          Exercise(
            name: "Battle Ropes",
            sets: "4",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.waves,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Metabolic Conditioning",
        description: "Circuit training to maximize calorie burn",
        icon: Icons.whatshot,
        exercises: [
          Exercise(
            name: equipment.contains("Kettlebells")
                ? "Kettlebell Swings"
                : "Jump Squats",
            sets: "4",
            reps: intensity == "beginner" ? "12" : "20",
            rest: "30 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: "Box Jumps",
            sets: "3",
            reps: intensity == "beginner" ? "8" : "12",
            rest: "45 sec",
            icon: Icons.height,
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Woodchops"
                : "Russian Twists",
            sets: "3",
            reps: "15 each side",
            rest: "30 sec",
            icon: Icons.rotate_right,
          ),
          Exercise(
            name: "Stair Master",
            sets: "3",
            reps: "3 minutes",
            rest: "60 sec",
            icon: Icons.stairs,
          ),
        ],
      ),
    ];
  } else {
    return [
      WorkoutPlan(
        name: "Home Fat Burn",
        description: "High-intensity bodyweight exercises for weight loss",
        icon: Icons.home_work,
        exercises: [
          Exercise(
            name: "Burpees",
            sets: intensity == "beginner" ? "2" : "4",
            reps: getIntensityBasedReps(intensity),
            rest: "45 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Mountain Climbers",
            sets: "3",
            reps: "${intensity == 'beginner' ? '30' : '45'} seconds",
            rest: "30 sec",
            icon: Icons.directions_run,
          ),
          Exercise(
            name: "High Knees",
            sets: "4",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.directions_run,
          ),
          Exercise(
            name: "Jumping Jacks",
            sets: "3",
            reps: "1 minute",
            rest: "30 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
      WorkoutPlan(
        name: "HIIT Cardio Blast",
        description: "High-intensity interval training without equipment",
        icon: Icons.timer,
        exercises: [
          Exercise(
            name: "Jump Squats",
            sets: "4",
            reps: intensity == "beginner" ? "10" : "15",
            rest: "30 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Plank to Downward Dog",
            sets: "3",
            reps: "10",
            rest: "30 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Lateral Jumps",
            sets: "3",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.swap_horiz,
          ),
          Exercise(
            name: "Star Jumps",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.grade,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Tabata Training",
        description: "20 seconds work, 10 seconds rest intervals",
        icon: Icons.timer,
        exercises: [
          Exercise(
            name: "Speed Skaters",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Squat Pulse",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Mountain Climbers Sprint",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.directions_run,
          ),
          Exercise(
            name: "Plank Hold",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.accessibility_new,
          ),
        ],
      ),
    ];
  }
}

String getIntensityBasedReps(String intensity) {
  switch (intensity) {
    case "beginner":
      return "8-10";
    case "intermediate":
      return "12-15";
    case "advanced":
      return "15-20";
    default:
      return "12";
  }
}

List<WorkoutPlan> getMuscleGainWorkouts({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  if (hasGymAccess && equipment.isNotEmpty) {
    return [
      WorkoutPlan(
        name: "Muscle Builder Pro",
        description: "Progressive overload training with gym equipment",
        icon: Icons.fitness_center,
        exercises: [
          Exercise(
            name: equipment.contains("Barbell")
                ? "Barbell Squats"
                : "Dumbbell Squats",
            sets: intensity == "beginner" ? "3" : "5",
            reps: "8-12",
            rest: "90 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: equipment.contains("Bench") ? "Bench Press" : "Push-ups",
            sets: "4",
            reps: intensity == "beginner" ? "8" : "12",
            rest: "90 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Rows"
                : "Inverted Rows",
            sets: "4",
            reps: "10-12",
            rest: "90 sec",
            icon: Icons.fitness_center,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Upper Body Power",
        description: "Focus on upper body muscle development",
        icon: Icons.fitness_center,
        exercises: [
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Dumbbell Press"
                : "Diamond Push-ups",
            sets: "4",
            reps: "8-12",
            rest: "60 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: equipment.contains("Pull-up Bar")
                ? "Pull-ups"
                : "Inverted Rows",
            sets: "3",
            reps: "8-10",
            rest: "90 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Lateral Raises"
                : "Pike Push-ups",
            sets: "3",
            reps: "12-15",
            rest: "60 sec",
            icon: Icons.fitness_center,
          ),
        ],
      ),
    ];
  } else {
    return [
      WorkoutPlan(
        name: "Bodyweight Muscle Builder",
        description: "Progressive calisthenics for muscle growth",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Diamond Push-ups",
            sets: "4",
            reps: intensity == "beginner" ? "8-10" : "12-15",
            rest: "60 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Bulgarian Split Squats",
            sets: "4",
            reps: "12 each leg",
            rest: "60 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Pike Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "6-8" : "10-12",
            rest: "60 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Inverted Rows",
            sets: "3",
            reps: "10-12",
            rest: "60 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Advanced Calisthenics",
        description: "Bodyweight exercises for maximum muscle activation",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Decline Push-ups",
            sets: "4",
            reps: "12-15",
            rest: "60 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Pistol Squats",
            sets: "3",
            reps: "8 each leg",
            rest: "90 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Handstand Wall Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "3-5" : "6-8",
            rest: "90 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "L-Sit Holds",
            sets: "3",
            reps: "20 seconds",
            rest: "60 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Core and Stability",
        description: "Build core strength and stability",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Planche Leans",
            sets: "4",
            reps: "20 seconds",
            rest: "45 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Dragon Flags",
            sets: "3",
            reps: intensity == "beginner" ? "5-8" : "8-12",
            rest: "60 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Hollow Body Holds",
            sets: "3",
            reps: "30 seconds",
            rest: "45 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Russian Twists",
            sets: "3",
            reps: "20 each side",
            rest: "45 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
    ];
  }
}

List<WorkoutPlan> getGeneralFitnessWorkouts({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  if (hasGymAccess) {
    return [
      WorkoutPlan(
        name: "Full Body Balance",
        description: "Balanced workout combining strength and cardio",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Rowing Machine",
            sets: "3",
            reps: "500 meters",
            rest: "60 sec",
            icon: Icons.rowing,
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Dumbbell Circuit"
                : "Bodyweight Circuit",
            sets: "3",
            reps: intensity == "beginner" ? "10" : "15",
            rest: "45 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Pulls"
                : "Band Pulls",
            sets: "3",
            reps: "12-15",
            rest: "45 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: "Stability Ball Core",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.circle,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Functional Fitness",
        description: "Movement patterns for everyday strength",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: equipment.contains("Kettlebells")
                ? "Kettlebell Swings"
                : "Good Mornings",
            sets: "3",
            reps: "12",
            rest: "45 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: "Medicine Ball Slams",
            sets: "3",
            reps: "10",
            rest: "45 sec",
            icon: Icons.fitness_center,
          ),
          Exercise(
            name: "TRX Rows",
            sets: "3",
            reps: "12",
            rest: "45 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Plank Variations",
            sets: "3",
            reps: "30 seconds each",
            rest: "30 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
    ];
  } else {
    return [
      WorkoutPlan(
        name: "Home Fitness Fundamentals",
        description: "Basic movements for overall fitness",
        icon: Icons.home_work,
        exercises: [
          Exercise(
            name: "Jumping Jacks",
            sets: "3",
            reps: "1 minute",
            rest: "30 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "5-8" : "10-12",
            rest: "45 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Bodyweight Squats",
            sets: "3",
            reps: "15",
            rest: "45 sec",
            icon: Icons.accessibility,
          ),
          Exercise(
            name: "Plank Hold",
            sets: "3",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.accessibility_new,
          ),
        ],
      ),
      WorkoutPlan(
        name: "Mobility & Strength",
        description: "Combine flexibility with strength training",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Sun Salutation",
            sets: "3",
            reps: "5 flows",
            rest: "30 sec",
            icon: Icons.wb_sunny,
          ),
          Exercise(
            name: "Walking Lunges",
            sets: "3",
            reps: "10 each leg",
            rest: "45 sec",
            icon: Icons.directions_walk,
          ),
          Exercise(
            name: "Bird Dogs",
            sets: "3",
            reps: "10 each side",
            rest: "30 sec",
            icon: Icons.accessibility_new,
          ),
          Exercise(
            name: "Superman Holds",
            sets: "3",
            reps: "20 seconds",
            rest: "30 sec",
            icon: Icons.accessibility,
          ),
        ],
      ),
    ];
  }
}

WorkoutPlan getCardioWorkout({
  required String intensity,
  required bool hasGymAccess,
  required String duration,
}) {
  if (hasGymAccess) {
    return WorkoutPlan(
      name: "Cardio Blast",
      description: "Mixed cardio for maximum endurance",
      icon: Icons.directions_run,
      exercises: [
        Exercise(
          name: "Treadmill Intervals",
          sets: intensity == "beginner" ? "3" : "5",
          reps: "1 minute run, 1 minute walk",
          rest: "30 sec",
          icon: Icons.directions_run,
        ),
        Exercise(
          name: "Elliptical Sprints",
          sets: "4",
          reps: "2 minutes",
          rest: "60 sec",
          icon: Icons.accessibility,
        ),
        Exercise(
          name: "Stair Climber",
          sets: "3",
          reps: "3 minutes",
          rest: "60 sec",
          icon: Icons.stairs,
        ),
        Exercise(
          name: "Rowing Sprints",
          sets: "4",
          reps: "250 meters",
          rest: "60 sec",
          icon: Icons.rowing,
        ),
      ],
    );
  } else {
    return WorkoutPlan(
      name: "Home Cardio",
      description: "Equipment-free cardio workout",
      icon: Icons.home_work,
      exercises: [
        Exercise(
          name: "High Knees",
          sets: intensity == "beginner" ? "3" : "4",
          reps: "45 seconds",
          rest: "30 sec",
          icon: Icons.directions_run,
        ),
        Exercise(
          name: "Mountain Climbers",
          sets: "4",
          reps: "30 seconds",
          rest: "30 sec",
          icon: Icons.accessibility_new,
        ),
        Exercise(
          name: "Jumping Jacks",
          sets: "3",
          reps: "1 minute",
          rest: "30 sec",
          icon: Icons.accessibility,
        ),
        Exercise(
          name: "Burpee Variations",
          sets: "3",
          reps: intensity == "beginner" ? "8" : "12",
          rest: "45 sec",
          icon: Icons.accessibility_new,
        ),
      ],
    );
  }
}

WorkoutPlan getStrengthWorkout({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  if (hasGymAccess) {
    return WorkoutPlan(
      name: "Strength Focus",
      description: "Build strength with compound movements",
      icon: Icons.fitness_center,
      exercises: [
        Exercise(
          name: equipment.contains("Barbell")
              ? "Deadlifts"
              : "Romanian Deadlifts",
          sets: intensity == "beginner" ? "3" : "4",
          reps: "8-12",
          rest: "90 sec",
          icon: Icons.fitness_center,
        ),
        Exercise(
          name: equipment.contains("Dumbbells")
              ? "Shoulder Press"
              : "Pike Push-ups",
          sets: "3",
          reps: intensity == "beginner" ? "8" : "12",
          rest: "60 sec",
          icon: Icons.accessibility_new,
        ),
        Exercise(
          name: equipment.contains("Cable Machine")
              ? "Cable Rows"
              : "Inverted Rows",
          sets: "3",
          reps: "12",
          rest: "60 sec",
          icon: Icons.fitness_center,
        ),
        Exercise(
          name:
              equipment.contains("Barbell") ? "Front Squats" : "Goblet Squats",
          sets: "3",
          reps: "10",
          rest: "90 sec",
          icon: Icons.fitness_center,
        ),
      ],
    );
  } else {
    return WorkoutPlan(
      name: "Bodyweight Strength",
      description: "Build strength using your body weight",
      icon: Icons.accessibility_new,
      exercises: [
        Exercise(
          name: "Push-up Variations",
          sets: "4",
          reps: intensity == "beginner" ? "8" : "12",
          rest: "60 sec",
          icon: Icons.accessibility_new,
        ),
        Exercise(
          name: "Bodyweight Squats",
          sets: "4",
          reps: intensity == "beginner" ? "12" : "20",
          rest: "60 sec",
          icon: Icons.accessibility,
        ),
        Exercise(
          name: "Dips",
          sets: "3",
          reps: intensity == "beginner" ? "5" : "10",
          rest: "60 sec",
          icon: Icons.accessibility_new,
        ),
        Exercise(
          name: "Glute Bridges",
          sets: "3",
          reps: "15",
          rest: "45 sec",
          icon: Icons.accessibility,
        ),
      ],
    );
  }
}
