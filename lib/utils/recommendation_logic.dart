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
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Run at high intensity for 1 minute",
              "Walk at moderate intensity for 2 minutes",
              "Repeat for the duration"
            ],
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Dumbbell Complex"
                : "Bodyweight Circuit",
            sets: "3",
            reps: getIntensityBasedReps(intensity),
            rest: "45 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Quadriceps", "Glutes", "Core"],
            instructions: [
              "Perform exercises in sequence",
              "Maintain proper form throughout",
              "Rest between sets as needed"
            ],
          ),
          Exercise(
            name: "Rowing Machine",
            sets: "3",
            reps: "500 meters",
            rest: "60 sec",
            icon: Icons.rowing,
            musclesWorked: ["Back", "Legs", "Core", "Shoulders"],
            instructions: [
              "Sit on rowing machine with feet strapped in",
              "Pull handle towards chest while extending legs",
              "Return to starting position with control"
            ],
          ),
          Exercise(
            name: "Battle Ropes",
            sets: "4",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.waves,
            musclesWorked: ["Shoulders", "Arms"],
            instructions: [
              "Hold ropes in hands",
              "Swings to create tension",
              "Return to starting position"
            ],
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
            musclesWorked: ["Quadriceps", "Glutes", "Core"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Keep your back straight",
              "Lower your body until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Box Jumps",
            sets: "3",
            reps: intensity == "beginner" ? "8" : "12",
            rest: "45 sec",
            icon: Icons.height,
            musclesWorked: ["Quadriceps", "Glutes"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Jump up to a box",
              "Land softly on the box"
            ],
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Woodchops"
                : "Russian Twists",
            sets: "3",
            reps: "15 each side",
            rest: "30 sec",
            icon: Icons.rotate_right,
            musclesWorked: ["Back", "Biceps"],
            instructions: [
              "Sit on cable machine with feet on platform",
              "Pull handles towards lower chest",
              "Keep back straight",
              "Return to starting position"
            ],
          ),
          Exercise(
            name: "Stair Master",
            sets: "3",
            reps: "3 minutes",
            rest: "60 sec",
            icon: Icons.stairs,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Walk or run up and down stairs",
              "Maintain proper form",
              "Repeat for the duration"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "High-Intensity Circuit",
        description: "Intense circuit training for maximum fat burn",
        icon: Icons.flash_on,
        exercises: [
          Exercise(
            name: "Assault Bike Sprints",
            sets: "5",
            reps: "30 seconds all-out",
            rest: "30 sec",
            icon: Icons.directions_bike,
            musclesWorked: ["Legs", "Cardiovascular", "Arms"],
            instructions: [
              "Sit on assault bike with proper posture",
              "Pedal and push/pull handles as fast as possible",
              "Maintain maximum effort for full duration"
            ],
          ),
          Exercise(
            name: equipment.contains("Kettlebells")
                ? "Kettlebell Clean and Press"
                : "Dumbbell Clean and Press",
            sets: "4",
            reps: "10 each side",
            rest: "45 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Shoulders", "Core", "Legs", "Back"],
            instructions: [
              "Start with weight between feet",
              "Explosively pull weight to shoulder",
              "Press weight overhead",
              "Return to starting position with control"
            ],
          ),
          Exercise(
            name: "Sled Push/Pull",
            sets: "3",
            reps: "30 meters each direction",
            rest: "60 sec",
            icon: Icons.arrow_forward,
            musclesWorked: ["Legs", "Core", "Back", "Shoulders"],
            instructions: [
              "Push sled forward with low body position",
              "Maintain steady pace and proper form",
              "Pull sled backward using rope or handles",
              "Complete full distance without stopping"
            ],
          ),
          Exercise(
            name: "Medicine Ball Slams",
            sets: "3",
            reps: "15",
            rest: "45 sec",
            icon: Icons.sports_handball,
            musclesWorked: ["Core", "Shoulders", "Back"],
            instructions: [
              "Hold medicine ball overhead",
              "Forcefully slam ball to ground using core",
              "Catch ball on bounce or pick up and repeat",
              "Maintain explosive power throughout"
            ],
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
            musclesWorked: ["Full Body"],
            instructions: [
              "Stand with feet together",
              "Jump up to standing position",
              "Return to squat position"
            ],
          ),
          Exercise(
            name: "Mountain Climbers",
            sets: "3",
            reps: "${intensity == 'beginner' ? '30' : '45'} seconds",
            rest: "30 sec",
            icon: Icons.directions_run,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand on hands and feet",
              "Climb up and down",
              "Maintain proper form"
            ],
          ),
          Exercise(
            name: "High Knees",
            sets: "4",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.directions_run,
            musclesWorked: ["Legs"],
            instructions: [
              "Stand with feet together",
              "Lift knees up to waist",
              "Lower back down"
            ],
          ),
          Exercise(
            name: "Jumping Jacks",
            sets: "3",
            reps: "1 minute",
            rest: "30 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Jump up to standing position",
              "Return to squat position"
            ],
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
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Jump up to standing position",
              "Land softly on the ground"
            ],
          ),
          Exercise(
            name: "Plank to Downward Dog",
            sets: "3",
            reps: "10",
            rest: "30 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Core"],
            instructions: [
              "Start in plank position",
              "Extend legs into downward dog",
              "Return to plank position"
            ],
          ),
          Exercise(
            name: "Lateral Jumps",
            sets: "3",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.swap_horiz,
            musclesWorked: ["Legs"],
            instructions: [
              "Stand with feet together",
              "Jump to one side",
              "Land softly on the ground"
            ],
          ),
          Exercise(
            name: "Star Jumps",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.grade,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Jump up to standing position",
              "Land softly on the ground"
            ],
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
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Skate in place",
              "Repeat for the duration"
            ],
          ),
          Exercise(
            name: "Squat Pulse",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.accessibility_new,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Squat down to a chair",
              "Return to standing position"
            ],
          ),
          Exercise(
            name: "Mountain Climbers Sprint",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.directions_run,
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Climb up and down",
              "Repeat for the duration"
            ],
          ),
          Exercise(
            name: "Plank Hold",
            sets: "4",
            reps: "20 seconds work, 10 seconds rest",
            rest: "60 sec between sets",
            icon: Icons.accessibility_new,
            musclesWorked: ["Core"],
            instructions: [
              "Start in plank position",
              "Hold for the specified time"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "Metabolic Bodyweight Burn",
        description: "Fast-paced workout to maximize calorie burn at home",
        icon: Icons.whatshot,
        exercises: [
          Exercise(
            name: "Jumping Lunges",
            sets: "4",
            reps: intensity == "beginner" ? "10 each leg" : "15 each leg",
            rest: "30 sec",
            icon: Icons.accessibility_new,
            musclesWorked: [
              "Quadriceps",
              "Glutes",
              "Hamstrings",
              "Cardiovascular"
            ],
            instructions: [
              "Start in lunge position",
              "Jump explosively and switch legs mid-air",
              "Land softly and immediately lower into next lunge",
              "Maintain balance and control throughout"
            ],
          ),
          Exercise(
            name: "Plank Jacks",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Core", "Shoulders", "Cardiovascular"],
            instructions: [
              "Start in plank position with feet together",
              "Jump feet wide apart and then back together",
              "Maintain rigid plank position throughout",
              "Keep pace consistent and controlled"
            ],
          ),
          Exercise(
            name: "Bear Crawl Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "8" : "12",
            rest: "45 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Core", "Shoulders", "Triceps"],
            instructions: [
              "Start in bear position (hands and feet on ground, knees hovering)",
              "Perform push-up while maintaining position",
              "Keep core engaged and back flat",
              "Move deliberately with control"
            ],
          ),
          Exercise(
            name: "Skater Hops",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.swap_horiz,
            musclesWorked: ["Legs", "Glutes", "Cardiovascular"],
            instructions: [
              "Stand on one leg",
              "Jump laterally to other leg",
              "Touch floor with hand if needed for balance",
              "Maintain continuous lateral movement"
            ],
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
            musclesWorked: ["Quadriceps", "Glutes", "Core"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Keep your back straight",
              "Lower your body until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: equipment.contains("Bench") ? "Bench Press" : "Push-ups",
            sets: "4",
            reps: intensity == "beginner" ? "8" : "12",
            rest: "90 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Lie on bench with feet flat on ground",
              "Grip bar slightly wider than shoulders",
              "Lower bar to chest",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Rows"
                : "Inverted Rows",
            sets: "4",
            reps: "10-12",
            rest: "90 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Back", "Biceps", "Rear Deltoids"],
            instructions: [
              "Sit at cable machine with feet on platform",
              "Pull handles towards lower chest",
              "Keep back straight",
              "Return to starting position"
            ],
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
            musclesWorked: ["Shoulders", "Triceps", "Chest"],
            instructions: [
              "Hold dumbbells at shoulder level",
              "Press weights overhead",
              "Lower back to starting position"
            ],
          ),
          Exercise(
            name: equipment.contains("Pull-up Bar")
                ? "Pull-ups"
                : "Inverted Rows",
            sets: "3",
            reps: "8-10",
            rest: "90 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Back", "Biceps", "Rear Deltoids"],
            instructions: [
              "Hang from bar with overhand grip",
              "Pull body up until chin clears bar",
              "Lower back down with control"
            ],
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Lateral Raises"
                : "Pike Push-ups",
            sets: "3",
            reps: "12-15",
            rest: "60 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Shoulders", "Upper Chest", "Triceps"],
            instructions: [
              "Hold dumbbells at sides",
              "Raise arms to shoulder level",
              "Lower back down with control"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "Power Hypertrophy",
        description: "Heavy compound movements followed by isolation work",
        icon: Icons.fitness_center,
        exercises: [
          Exercise(
            name: equipment.contains("Barbell")
                ? "Barbell Rows"
                : "Dumbbell Rows",
            sets: "5",
            reps: "6-8",
            rest: "90 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Back", "Biceps", "Forearms", "Core"],
            instructions: [
              "Bend at hips with flat back",
              "Pull weight to lower ribcage",
              "Squeeze shoulder blades together at top",
              "Lower weight with control"
            ],
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Flyes"
                : "Dumbbell Flyes",
            sets: "4",
            reps: "10-12",
            rest: "60 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Chest", "Shoulders"],
            instructions: [
              "Lie on bench or stand at cable machine",
              "Start with arms wide",
              "Bring weights/handles together in arcing motion",
              "Focus on chest contraction at peak"
            ],
          ),
          Exercise(
            name: equipment.contains("Leg Press") ? "Leg Press" : "Hack Squat",
            sets: "4",
            reps: "8-12",
            rest: "90 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Quadriceps", "Glutes", "Hamstrings"],
            instructions: [
              "Position feet shoulder-width apart",
              "Lower weight with control to 90-degree knee angle",
              "Press through heels to starting position",
              "Avoid locking knees at top"
            ],
          ),
          Exercise(
            name: "Face Pulls",
            sets: "3",
            reps: "15-20",
            rest: "60 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Rear Deltoids", "Rotator Cuff", "Upper Back"],
            instructions: [
              "Set cable at head height",
              "Pull rope to face with elbows high",
              "Focus on external rotation at end position",
              "Control movement throughout range"
            ],
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
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Lie on the ground",
              "Place hands slightly wider than shoulders",
              "Lower body down to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Bulgarian Split Squats",
            sets: "4",
            reps: "12 each leg",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Quadriceps", "Glutes"],
            instructions: [
              "Stand with one foot forward",
              "Lower body down until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Pike Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "6-8" : "10-12",
            rest: "60 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Shoulders", "Upper Chest", "Triceps"],
            instructions: [
              "Stand on hands and feet",
              "Lift one leg up",
              "Lower back down with control"
            ],
          ),
          Exercise(
            name: "Inverted Rows",
            sets: "3",
            reps: "10-12",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Back", "Biceps"],
            instructions: [
              "Hang from bar with overhand grip",
              "Pull body up until chin clears bar",
              "Lower back down with control"
            ],
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
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Lie on a decline bench",
              "Lower body down",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Pistol Squats",
            sets: "3",
            reps: "8 each leg",
            rest: "90 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Quadriceps", "Glutes"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Lower body down until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Handstand Wall Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "3-5" : "6-8",
            rest: "90 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Stand on hands and feet",
              "Lift body up",
              "Push back down with control"
            ],
          ),
          Exercise(
            name: "L-Sit Holds",
            sets: "3",
            reps: "20 seconds",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Core"],
            instructions: [
              "Sit on the ground",
              "Lift one leg up",
              "Hold for the specified time"
            ],
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
            musclesWorked: ["Core"],
            instructions: [
              "Lie on the ground",
              "Lift one leg up",
              "Lower body down"
            ],
          ),
          Exercise(
            name: "Dragon Flags",
            sets: "3",
            reps: intensity == "beginner" ? "5-8" : "8-12",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Core"],
            instructions: [
              "Lie on the ground",
              "Lift one arm and one leg up",
              "Lower back down"
            ],
          ),
          Exercise(
            name: "Hollow Body Holds",
            sets: "3",
            reps: "30 seconds",
            rest: "45 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Core"],
            instructions: [
              "Lie on the ground",
              "Lift one arm and one leg up",
              "Lower back down"
            ],
          ),
          Exercise(
            name: "Russian Twists",
            sets: "3",
            reps: "20 each side",
            rest: "45 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Core"],
            instructions: [
              "Sit on the ground",
              "Lift one arm and one leg up",
              "Twist body"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "Progressive Overload Calisthenics",
        description: "Advanced bodyweight training for muscle development",
        icon: Icons.accessibility_new,
        exercises: [
          Exercise(
            name: "Archer Push-ups",
            sets: "4",
            reps: intensity == "beginner" ? "4-6 each side" : "8-10 each side",
            rest: "60 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Start in push-up position",
              "Extend one arm to side",
              "Lower body toward hand on ground",
              "Push back up and alternate sides"
            ],
          ),
          Exercise(
            name: "Weighted Chin-ups",
            sets: "4",
            reps: intensity == "beginner" ? "5-8" : "8-12",
            rest: "90 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Back", "Biceps", "Core"],
            instructions: [
              "Add weight via backpack or weight vest if available",
              "Hang from bar with underhand grip",
              "Pull chin over bar with controlled movement",
              "Lower with full extension at bottom"
            ],
          ),
          Exercise(
            name: "Single-Leg Romanian Deadlifts",
            sets: "3",
            reps: "10-12 each leg",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Hamstrings", "Glutes", "Lower Back", "Core"],
            instructions: [
              "Stand on one leg",
              "Hinge at hips while extending other leg behind",
              "Keep back flat and core engaged",
              "Return to standing by squeezing glute"
            ],
          ),
          Exercise(
            name: "Pseudo Planche Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "6-8" : "10-12",
            rest: "60 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Shoulders", "Triceps", "Core"],
            instructions: [
              "Start in push-up position with hands at waist level",
              "Lean forward shifting weight over hands",
              "Perform push-up maintaining forward lean",
              "Keep body rigid throughout movement"
            ],
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
            musclesWorked: ["Back", "Legs", "Core", "Shoulders"],
            instructions: [
              "Sit on rowing machine with feet strapped in",
              "Pull handle towards chest while extending legs",
              "Return to starting position with control"
            ],
          ),
          Exercise(
            name: equipment.contains("Dumbbells")
                ? "Dumbbell Circuit"
                : "Bodyweight Circuit",
            sets: "3",
            reps: intensity == "beginner" ? "10" : "15",
            rest: "45 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Full Body", "Core", "Cardiovascular"],
            instructions: [
              "Perform exercises in sequence",
              "Maintain proper form throughout",
              "Rest between sets as needed"
            ],
          ),
          Exercise(
            name: equipment.contains("Cable Machine")
                ? "Cable Pulls"
                : "Band Pulls",
            sets: "3",
            reps: "12-15",
            rest: "45 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Back", "Shoulders", "Arms"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Pull handles towards chest",
              "Return to starting position"
            ],
          ),
          Exercise(
            name: "Stability Ball Core",
            sets: "3",
            reps: "45 seconds",
            rest: "30 sec",
            icon: Icons.circle,
            musclesWorked: ["Core", "Lower Back", "Hip Flexors"],
            instructions: [
              "Lie on stability ball",
              "Keep core engaged",
              "Hold position for specified time"
            ],
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
            musclesWorked: ["Full Body"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Swing kettlebell to shoulder",
              "Return to starting position"
            ],
          ),
          Exercise(
            name: "Medicine Ball Slams",
            sets: "3",
            reps: "10",
            rest: "45 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Full Body"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Slam medicine ball to chest",
              "Return to starting position"
            ],
          ),
          Exercise(
            name: "TRX Rows",
            sets: "3",
            reps: "12",
            rest: "45 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Back", "Biceps"],
            instructions: [
              "Hang from TRX bar",
              "Pull body up until chin clears bar",
              "Lower back down with control"
            ],
          ),
          Exercise(
            name: "Plank Variations",
            sets: "3",
            reps: "30 seconds each",
            rest: "30 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Core"],
            instructions: [
              "Start in plank position",
              "Hold for the specified time"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "Functional Strength Circuit",
        description: "Build practical strength and movement patterns",
        icon: Icons.sync,
        exercises: [
          Exercise(
            name: "Landmine Rotations",
            sets: "3",
            reps: "10 each side",
            rest: "45 sec",
            icon: Icons.rotate_right,
            musclesWorked: ["Core", "Shoulders", "Hips"],
            instructions: [
              "Set up landmine or secure barbell in corner",
              "Hold end with both hands at chest height",
              "Rotate through core to move bar side to side",
              "Keep lower body stable throughout"
            ],
          ),
          Exercise(
            name: "Farmer's Carries",
            sets: "3",
            reps: "40 meters",
            rest: "60 sec",
            icon: Icons.fitness_center,
            musclesWorked: ["Forearms", "Traps", "Core", "Legs"],
            instructions: [
              "Hold heavy weights at sides",
              "Walk with controlled pace and good posture",
              "Keep shoulders down and core tight",
              "Complete distance without setting weights down"
            ],
          ),
          Exercise(
            name: equipment.contains("Battle Ropes")
                ? "Battle Rope Waves"
                : "Medicine Ball Slams",
            sets: "3",
            reps: "30 seconds",
            rest: "45 sec",
            icon: Icons.waves,
            musclesWorked: ["Shoulders", "Arms", "Core", "Cardiovascular"],
            instructions: [
              "Hold rope ends with firm grip",
              "Create alternating or simultaneous waves",
              "Keep lower body stable and core engaged",
              "Maintain consistent intensity throughout set"
            ],
          ),
          Exercise(
            name: "Sled Drag",
            sets: "3",
            reps: "30 meters",
            rest: "60 sec",
            icon: Icons.arrow_back,
            musclesWorked: ["Legs", "Back", "Core"],
            instructions: [
              "Attach harness or hold straps",
              "Lean forward and drive with legs",
              "Take short, powerful steps",
              "Maintain tension throughout movement"
            ],
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
            musclesWorked: ["Legs", "Cardiovascular"],
            instructions: [
              "Stand with feet together",
              "Jump up to standing position",
              "Return to squat position"
            ],
          ),
          Exercise(
            name: "Push-ups",
            sets: "3",
            reps: intensity == "beginner" ? "5-8" : "10-12",
            rest: "45 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Chest", "Shoulders", "Triceps"],
            instructions: [
              "Lie on the ground",
              "Place hands slightly wider than shoulders",
              "Lower body down",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Bodyweight Squats",
            sets: "3",
            reps: "15",
            rest: "45 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Quadriceps", "Glutes"],
            instructions: [
              "Stand with feet shoulder-width apart",
              "Lower body down until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Plank Hold",
            sets: "3",
            reps: "30 seconds",
            rest: "30 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Core"],
            instructions: [
              "Lie on the ground",
              "Lift one arm and one leg up",
              "Lower back down"
            ],
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
            musclesWorked: ["Full Body"],
            instructions: [
              "Stand with feet together",
              "Lift one arm and one leg up",
              "Lower body down"
            ],
          ),
          Exercise(
            name: "Walking Lunges",
            sets: "3",
            reps: "10 each leg",
            rest: "45 sec",
            icon: Icons.directions_walk,
            musclesWorked: ["Legs"],
            instructions: [
              "Stand with feet together",
              "Lift one leg forward",
              "Lower body down until thighs are parallel to the ground",
              "Push back up to starting position"
            ],
          ),
          Exercise(
            name: "Bird Dogs",
            sets: "3",
            reps: "10 each side",
            rest: "30 sec",
            icon: Icons.accessibility_new,
            musclesWorked: ["Back", "Core"],
            instructions: [
              "Lie on the ground",
              "Lift one arm and one leg up",
              "Lower body down"
            ],
          ),
          Exercise(
            name: "Superman Holds",
            sets: "3",
            reps: "20 seconds",
            rest: "30 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Back", "Core"],
            instructions: [
              "Lie on the ground",
              "Lift one arm and one leg up",
              "Lower body down"
            ],
          ),
        ],
      ),
      WorkoutPlan(
        name: "Movement Flow",
        description: "Fluid movement patterns for strength and mobility",
        icon: Icons.waves,
        exercises: [
          Exercise(
            name: "Flow Sequence",
            sets: "3",
            reps: "45 seconds each movement",
            rest: "30 sec between movements, 60 sec between sets",
            icon: Icons.accessibility_new,
            musclesWorked: ["Full Body", "Core", "Mobility"],
            instructions: [
              "Move through: Squat → Lunge → Push-up → Downward Dog",
              "Connect movements fluidly without pausing",
              "Focus on breath and movement coordination",
              "Maintain control and proper form throughout"
            ],
          ),
          Exercise(
            name: "Animal Flow",
            sets: "3",
            reps: "30 seconds each movement",
            rest: "30 sec between movements, 60 sec between sets",
            icon: Icons.pets,
            musclesWorked: ["Core", "Shoulders", "Hips", "Mobility"],
            instructions: [
              "Cycle through: Bear crawl → Crab walk → Ape walk",
              "Keep core engaged throughout transitions",
              "Move deliberately with control",
              "Focus on full range of motion"
            ],
          ),
          Exercise(
            name: "Turkish Get-up",
            sets: "3",
            reps: "3-5 each side",
            rest: "60 sec",
            icon: Icons.accessibility,
            musclesWorked: ["Shoulders", "Core", "Legs", "Coordination"],
            instructions: [
              "Start lying down with arm extended holding weight (or without weight)",
              "Rise to standing position through specific movement pattern",
              "Reverse movement to return to floor",
              "Focus on stability and control throughout"
            ],
          ),
          Exercise(
            name: "Yoga Flow",
            sets: "2",
            reps: "2 minutes",
            rest: "60 sec",
            icon: Icons.self_improvement,
            musclesWorked: ["Full Body", "Flexibility", "Balance"],
            instructions: [
              "Flow through: Warrior poses → Triangle → Side angle → Reverse warrior",
              "Coordinate movement with breath",
              "Hold each position for 3-5 breaths",
              "Focus on alignment and stability"
            ],
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
      name: "Cardio Blast Pro",
      description: "Advanced cardio training for endurance and fat loss",
      icon: Icons.directions_run,
      exercises: [
        Exercise(
          name: "Treadmill Intervals",
          sets: intensity == "beginner" ? "3" : "5",
          reps: "1 minute run, 1 minute walk",
          rest: "30 sec",
          icon: Icons.directions_run,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Run at high intensity (80-90% max effort) for 1 minute",
            "Walk at moderate intensity for 1 minute recovery",
            "Increase incline for greater challenge",
            "Maintain proper running form throughout"
          ],
        ),
        Exercise(
          name: "Elliptical Sprints",
          sets: "4",
          reps: "2 minutes",
          rest: "60 sec",
          icon: Icons.accessibility,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Increase resistance for sprint intervals",
            "Push with both arms and legs for full-body engagement",
            "Maintain consistent cadence during sprints",
            "Focus on controlled breathing"
          ],
        ),
        Exercise(
          name: "Stair Climber",
          sets: "3",
          reps: "3 minutes",
          rest: "60 sec",
          icon: Icons.stairs,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Maintain upright posture (avoid leaning on console)",
            "Take full steps using entire foot",
            "Alternate between double-steps and regular pace",
            "Use minimal hand support for balance"
          ],
        ),
        Exercise(
          name: "Rowing Sprints",
          sets: "4",
          reps: "250 meters",
          rest: "60 sec",
          icon: Icons.rowing,
          musclesWorked: ["Full Body", "Cardiovascular"],
          instructions: [
            "Focus on proper form: legs-core-arms, arms-core-legs",
            "Drive with legs first, then pull with back and arms",
            "Maintain consistent power throughout stroke",
            "Aim for specific split time based on fitness level"
          ],
        ),
        Exercise(
          name: "Assault Bike Tabata",
          sets: "4",
          reps: "20 seconds all-out, 10 seconds rest",
          rest: "60 sec between sets",
          icon: Icons.directions_bike,
          musclesWorked: ["Full Body", "Cardiovascular"],
          instructions: [
            "Give maximum effort during 20-second work periods",
            "Use both arms and legs with powerful movements",
            "Focus on quick transitions between rest and work",
            "Maintain proper posture throughout"
          ],
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
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Stand with feet together",
            "Lift one knee up to waist",
            "Lower back down"
          ],
        ),
        Exercise(
          name: "Mountain Climbers",
          sets: "4",
          reps: "30 seconds",
          rest: "30 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Stand on hands and feet",
            "Climb up and down",
            "Maintain proper form"
          ],
        ),
        Exercise(
          name: "Jumping Jacks",
          sets: "3",
          reps: "1 minute",
          rest: "30 sec",
          icon: Icons.accessibility,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Stand with feet together",
            "Jump up to standing position",
            "Return to squat position"
          ],
        ),
        Exercise(
          name: "Burpee Variations",
          sets: "3",
          reps: intensity == "beginner" ? "8" : "12",
          rest: "45 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Legs", "Cardiovascular"],
          instructions: [
            "Stand with feet together",
            "Jump up to standing position",
            "Lower body down",
            "Jump back up to standing position"
          ],
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
      name: "Complete Strength System",
      description: "Comprehensive strength training for total body development",
      icon: Icons.fitness_center,
      exercises: [
        Exercise(
          name: equipment.contains("Barbell")
              ? "Barbell Deadlifts"
              : "Dumbbell Romanian Deadlifts",
          sets: intensity == "beginner" ? "3" : "5",
          reps: intensity == "beginner" ? "5-8" : "3-6",
          rest: "120 sec",
          icon: Icons.fitness_center,
          musclesWorked: ["Back", "Glutes", "Hamstrings", "Forearms", "Traps"],
          instructions: [
            "Stand with feet hip-width apart, bar over mid-foot",
            "Hinge at hips with flat back, grasp bar with shoulder-width grip",
            "Drive through heels, extending hips and knees",
            "Keep bar close to body throughout movement",
            "Lower with control, maintaining neutral spine"
          ],
        ),
        Exercise(
          name: equipment.contains("Bench")
              ? "Incline Bench Press"
              : "Incline Dumbbell Press",
          sets: "4",
          reps: "8-10",
          rest: "90 sec",
          icon: Icons.fitness_center,
          musclesWorked: ["Upper Chest", "Shoulders", "Triceps"],
          instructions: [
            "Set bench to 30-45 degree incline",
            "Retract shoulder blades and maintain back arch",
            "Lower weight with control to upper chest",
            "Press upward and slightly backward to starting position",
            "Keep elbows at 45-degree angle to torso"
          ],
        ),
        Exercise(
          name: equipment.contains("Pull-up Bar")
              ? "Weighted Pull-ups"
              : "Lat Pulldowns",
          sets: "4",
          reps: intensity == "beginner" ? "6-8" : "8-12",
          rest: "90 sec",
          icon: Icons.fitness_center,
          musclesWorked: ["Back", "Biceps", "Forearms", "Core"],
          instructions: [
            "Grip bar slightly wider than shoulder width",
            "Initiate movement by depressing shoulder blades",
            "Pull body up until chin clears bar (or bar to upper chest)",
            "Lower with control to full hang position",
            "Maintain slight arch in lower back throughout"
          ],
        ),
        Exercise(
          name: equipment.contains("Squat Rack")
              ? "Front Squats"
              : "Goblet Squats",
          sets: "4",
          reps: "8-12",
          rest: "90 sec",
          icon: Icons.fitness_center,
          musclesWorked: ["Quadriceps", "Glutes", "Core", "Upper Back"],
          instructions: [
            "Position weight at front rack position (or hold at chest)",
            "Keep elbows high and torso upright",
            "Descend until thighs are parallel to ground or lower",
            "Drive through heels while maintaining upright position",
            "Keep knees tracking over toes throughout movement"
          ],
        ),
        Exercise(
          name: equipment.contains("Cable Machine")
              ? "Cable Face Pulls"
              : "Dumbbell External Rotations",
          sets: "3",
          reps: "12-15",
          rest: "60 sec",
          icon: Icons.fitness_center,
          musclesWorked: ["Rear Deltoids", "Rotator Cuff", "Mid Traps"],
          instructions: [
            "Set cable at upper chest height with rope attachment",
            "Pull rope toward face with elbows high and out",
            "Focus on external rotation at end position",
            "Squeeze shoulder blades together at peak contraction",
            "Control the return to starting position"
          ],
        ),
      ],
    );
  } else {
    return WorkoutPlan(
      name: "Advanced Bodyweight Strength",
      description: "Progressive calisthenics for strength development",
      icon: Icons.accessibility_new,
      exercises: [
        Exercise(
          name: "Deficit Push-ups",
          sets: "4",
          reps: intensity == "beginner" ? "8-10" : "12-15",
          rest: "60 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Chest", "Shoulders", "Triceps", "Core"],
          instructions: [
            "Place hands on elevated surface (books or blocks)",
            "Lower chest below hand level for increased range of motion",
            "Maintain rigid body alignment throughout movement",
            "Push explosively back to starting position",
            "Focus on full chest stretch at bottom position"
          ],
        ),
        Exercise(
          name: "Bulgarian Split Squats",
          sets: "4",
          reps: "10-12 each leg",
          rest: "60 sec",
          icon: Icons.accessibility,
          musclesWorked: ["Quadriceps", "Glutes", "Hamstrings", "Core"],
          instructions: [
            "Place rear foot on elevated surface (couch, chair, etc.)",
            "Position front foot far enough forward for vertical shin at bottom",
            "Lower until front thigh is parallel to ground",
            "Drive through front heel to return to starting position",
            "Maintain upright torso throughout movement"
          ],
        ),
        Exercise(
          name: "Pull-up Variations",
          sets: "4",
          reps: intensity == "beginner" ? "5-8" : "8-12",
          rest: "90 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Back", "Biceps", "Forearms", "Core"],
          instructions: [
            "Use doorway pull-up bar or sturdy overhead surface",
            "Vary grip width and orientation for different emphasis",
            "Pull chest to bar with controlled movement",
            "Lower to full hang between repetitions",
            "For beginners: use chair assist or jumping variations"
          ],
        ),
        Exercise(
          name: "Pike Push-ups",
          sets: "3",
          reps: intensity == "beginner" ? "6-8" : "10-12",
          rest: "60 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Shoulders", "Triceps", "Upper Chest", "Core"],
          instructions: [
            "Form inverted V-shape with body, feet hip-width apart",
            "Position hands slightly wider than shoulders",
            "Lower head toward ground between hands",
            "Push back to starting position with full arm extension",
            "Elevate feet for increased difficulty (advanced)"
          ],
        ),
        Exercise(
          name: "Hollow Body Hold to V-up",
          sets: "3",
          reps: "30 sec hold + 10 V-ups",
          rest: "60 sec",
          icon: Icons.accessibility,
          musclesWorked: ["Core", "Hip Flexors", "Lower Back"],
          instructions: [
            "Begin in hollow body position (lower back pressed to floor)",
            "Hold position with arms and legs extended, shoulders off ground",
            "After hold time, transition to V-up movement",
            "Touch hands to feet at top position of V-up",
            "Control descent back to hollow position for each rep"
          ],
        ),
      ],
    );
  }
}
