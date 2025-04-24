import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup.dart';
import 'firstlogin.dart';
import 'select_gender.dart';
import 'set_goal.dart';
import 'birth_year.dart';
import 'set_height.dart';
import 'set_weight.dart';
import 'set_weight_mannually.dart';
import 'splash_screen.dart';
import 'screens/recommendations_page.dart';
import 'pref_workout.dart';
import 'gym_equipment.dart';
import 'work_place.dart';
import 'allset_page.dart';
import 'SummaryPage/summary_page.dart';
import 'SummaryPage/steps_page.dart';
import 'SummaryPage/measure_weight.dart';
import 'auth_check.dart';
import 'intro_screen.dart';
import 'models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/start_workout_page.dart';
import 'screens/workout_tracker_page.dart';
import 'screens/workout_history_page.dart';
import 'services/steps_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with default options
  await Firebase.initializeApp();
  
  // Initialize the steps tracking service
  final stepsService = StepsTrackingService();
  await stepsService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    home: const SplashScreen(),
    debugShowCheckedModeBanner: false,
    title: 'FitScale',
    theme: ThemeData.dark(),
    routes: {
      '/signup': (context) => const SignupPage(),
      '/login': (context) => const LoginPage(),
      '/select_gender': (context) => const SelectGenderPage(),
      '/set_goal': (context) => const SetGoalPage(),
      '/birth_year': (context) => const BirthYearPage(),
      '/set_height': (context) => const SetHeightPage(),
      '/set_weight': (context) => const SetWeightPage(),
      '/set_weight_mannually': (context) => const SetWeightManuallyPage(),
      '/pref_workout': (context) => PrefWorkoutPage(),
      '/work_place': (context) => const WorkPlacePage(),
      '/gym_equipment': (context) => const GymEquipmentPage(),
      '/all_set': (context) => const AllSetPage(),
      '/summary': (context) => const SummaryPage(),
      '/steps': (context) => const StepsPage(),
      '/measure_weight': (context) => const MeasureWeightPage(),
        '/start_workout': (context) => const StartWorkoutPage(),
        '/workout_history': (context) => const WorkoutHistoryPage(),
      '/workouts': (context) => RecommendationsPage(
            user: UserModel(
                id: 'user_id',
                email: 'user@example.com',
                gender: 'Male',
                goal: 'Build Muscle',
                age: 25,
                weight: 70.0,
                height: 175.0,
                activityLevel: 'Moderately Active',
                workoutPlace: 'Gym',
              setupCompleted: true,
              currentSetupStep: 'completed',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
      '/intro': (context) => const IntroScreen(),
    },
    );
  }
}
