// lib/utils/recommendation_logic.dart
import '../models/user_model.dart';
import '../models/workout_plan.dart';

List<WorkoutPlan> generateRecommendations(UserModel user) {
  List<WorkoutPlan> recommendations = [];

  if (user.goal == "Lose Weight") {
    recommendations.add(WorkoutPlan(
      name: "Cardio Blast",
      description: "High-intensity cardio workouts to burn calories.",
    ));
  } else if (user.goal == "Build Muscle") {
    recommendations.add(WorkoutPlan(
      name: "Strength Training",
      description: "Focus on weightlifting and resistance exercises.",
    ));
  } else if (user.goal == "Stay Fit") {
    recommendations.add(WorkoutPlan(
      name: "Balanced Routine",
      description: "A mix of cardio and strength exercises.",
    ));
  }

  // Add more logic based on other preferences if needed

  return recommendations;
}
