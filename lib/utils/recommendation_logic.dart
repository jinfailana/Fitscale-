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
      equipment: availableEquipment,
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Treadmill running image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Dumbbell workout image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Rowing machine image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Battle ropes image
          ),
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Kettlebell swings image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Box jumps image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Cable machine exercise image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1535743686920-55e4145369b9?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Stair climbing image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Kettlebell swings image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Box jumps image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Cable machine exercise image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1535743686920-55e4145369b9?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Stair climbing image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1520877880798-5ee004e3f11e?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Assault bike image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Kettlebell/dumbbell clean and press image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Sled push/pull image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Medicine ball exercises image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1576678927484-cc907957088c?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Burpees image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Mountain climbers image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // High knees image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Jumping jacks image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Jump squats image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Plank exercise image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Lateral jumps image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Star jumps image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Speed skaters image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Squat exercise image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Mountain climbers sprint image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Plank hold image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Jumping lunges image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Plank exercise image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Bear crawl push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Skater hops image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Squats image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571388208497-71bedc66e932?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Bench press image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Cable rows image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Dumbbell press image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Pull-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Lateral raises image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Barbell/dumbbell rows image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571388208497-71bedc66e932?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Chest flyes image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Leg press image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Face pulls image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Diamond push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Bulgarian split squats image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Pike push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Inverted rows image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Decline push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Pistol squats image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Handstand push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // L-sit image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Planche leans image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Dragon flags image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Hollow body holds image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Russian twists image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Archer push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Weighted chin-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Single-leg RDL image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">", // Pseudo planche push-ups image
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
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
            imageHtml:
                "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
          ),
        ],
      ),
    ];
  }
}

WorkoutPlan getCardioWorkout({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  return WorkoutPlan(
    name: "Cardio Training",
    description: "Improve cardiovascular endurance and burn calories",
    icon: Icons.directions_run,
    exercises: [
      Exercise(
        name: equipment.contains("Treadmill") ? "Treadmill Run" : "Outdoor Run",
        sets: "1",
        reps: "30 min",
        rest: "0 sec",
        icon: Icons.directions_run,
        musclesWorked: ["Legs", "Cardiovascular System"],
        instructions: [
          "Start with a light warm-up",
          "Maintain a steady pace",
          "Keep good posture",
          "Land midfoot with each step"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
      Exercise(
        name: "Jump Rope",
        sets: "3",
        reps: "2 min",
        rest: "30 sec",
        icon: Icons.sports_handball,
        musclesWorked: ["Calves", "Cardiovascular System"],
        instructions: [
          "Keep elbows close to body",
          "Jump on balls of feet",
          "Maintain rhythm",
          "Land softly"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
    ],
  );
}

WorkoutPlan getStrengthWorkout({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  return WorkoutPlan(
    name: "Strength Training",
    description: "Build muscle and increase strength",
    icon: Icons.fitness_center,
    exercises: [
      Exercise(
        name: equipment.contains("Barbell")
            ? "Barbell Squats"
            : "Bodyweight Squats",
        sets: "3",
        reps: "12",
        rest: "60 sec",
        icon: Icons.fitness_center,
        musclesWorked: ["Legs", "Core"],
        instructions: [
          "Stand with feet shoulder-width apart",
          "Keep your back straight",
          "Lower your body until thighs are parallel to the ground",
          "Push back up to starting position"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
      Exercise(
        name: equipment.contains("Dumbbells") ? "Dumbbell Press" : "Push-ups",
        sets: "3",
        reps: "12",
        rest: "60 sec",
        icon: Icons.fitness_center,
        musclesWorked: ["Chest", "Shoulders", "Triceps"],
        instructions: [
          "Start in push-up position",
          "Lower your body until chest nearly touches the ground",
          "Push back up to starting position"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
    ],
  );
}

WorkoutPlan getFlexibilityWorkout({
  required String intensity,
  required bool hasGymAccess,
  required List<String> equipment,
  required String duration,
}) {
  return WorkoutPlan(
    name: "Flexibility Training",
    description: "Improve range of motion and reduce muscle tension",
    icon: Icons.self_improvement,
    exercises: [
      Exercise(
        name: "Dynamic Stretching",
        sets: "1",
        reps: "10 min",
        rest: "0 sec",
        icon: Icons.accessibility_new,
        musclesWorked: ["Full Body"],
        instructions: [
          "Start with gentle movements",
          "Gradually increase range of motion",
          "Keep movements controlled",
          "Breathe deeply"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
      Exercise(
        name: "Static Stretching",
        sets: "3",
        reps: "30 sec",
        rest: "15 sec",
        icon: Icons.self_improvement,
        musclesWorked: ["Full Body"],
        instructions: [
          "Hold each stretch",
          "Don't bounce",
          "Breathe deeply",
          "Feel gentle tension"
        ],
        imageHtml:
            "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
      ),
    ],
  );
}

class WorkoutLogic {
  List<WorkoutPlan> getRecommendations({
    required String goal,
    required String fitnessLevel,
    required bool hasGymAccess,
    required List<String> equipment,
    required int duration,
  }) {
    List<WorkoutPlan> recommendations = [];

    // Add strength workout
    recommendations.add(getStrengthWorkout(
      intensity: fitnessLevel,
      hasGymAccess: hasGymAccess,
      equipment: equipment,
      duration: duration.toString(),
    ));

    // Add cardio workout
    recommendations.add(getCardioWorkout(
      intensity: fitnessLevel,
      hasGymAccess: hasGymAccess,
      equipment: equipment,
      duration: duration.toString(),
    ));

    // Add flexibility workout
    recommendations.add(getFlexibilityWorkout(
      intensity: fitnessLevel,
      hasGymAccess: hasGymAccess,
      equipment: equipment,
      duration: duration.toString(),
    ));

    return recommendations;
  }

  WorkoutPlan getCardioWorkout({
    required String intensity,
    required bool hasGymAccess,
    required List<String> equipment,
    required String duration,
  }) {
    return WorkoutPlan(
      name: "Cardio Training",
      description: "Improve cardiovascular endurance and burn calories",
      icon: Icons.directions_run,
      exercises: [
        Exercise(
          name:
              equipment.contains("Treadmill") ? "Treadmill Run" : "Outdoor Run",
          sets: "1",
          reps: "30 min",
          rest: "0 sec",
          icon: Icons.directions_run,
          musclesWorked: ["Legs", "Cardiovascular System"],
          instructions: [
            "Start with a light warm-up",
            "Maintain a steady pace",
            "Keep good posture",
            "Land midfoot with each step"
          ],
          imageHtml:
              "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
        ),
        Exercise(
          name: "Jump Rope",
          sets: "3",
          reps: "2 min",
          rest: "30 sec",
          icon: Icons.sports_handball,
          musclesWorked: ["Calves", "Cardiovascular System"],
          instructions: [
            "Keep elbows close to body",
            "Jump on balls of feet",
            "Maintain rhythm",
            "Land softly"
          ],
          imageHtml:
              "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
        ),
      ],
    );
  }

  WorkoutPlan getFlexibilityWorkout({
    required String intensity,
    required bool hasGymAccess,
    required List<String> equipment,
    required String duration,
  }) {
    return WorkoutPlan(
      name: "Flexibility Training",
      description: "Improve range of motion and reduce muscle tension",
      icon: Icons.self_improvement,
      exercises: [
        Exercise(
          name: "Dynamic Stretching",
          sets: "1",
          reps: "10 min",
          rest: "0 sec",
          icon: Icons.accessibility_new,
          musclesWorked: ["Full Body"],
          instructions: [
            "Start with gentle movements",
            "Gradually increase range of motion",
            "Keep movements controlled",
            "Breathe deeply"
          ],
          imageHtml:
              "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
        ),
        Exercise(
          name: "Static Stretching",
          sets: "3",
          reps: "30 sec",
          rest: "15 sec",
          icon: Icons.self_improvement,
          musclesWorked: ["Full Body"],
          instructions: [
            "Hold each stretch",
            "Don't bounce",
            "Breathe deeply",
            "Feel gentle tension"
          ],
          imageHtml:
              "<img src=\"https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop\" width=\"300\" height=\"200\" style=\"object-fit: cover;\">",
        ),
      ],
    );
  }

  // ... rest of the class ...
}
