import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import the Firebase core package
import 'signup.dart'; // Import the signup page
import 'firstlogin.dart'; // Import the login page
import 'select_gender.dart'; // Import the select gender page
// Add this import
// Import the select gender page
import 'set_goal.dart'; // Import your SetGoalPage
import 'birth_year.dart'; // Import the birth year page
import 'set_height.dart'; // Import the set height page
import 'set_weight.dart';
import 'set_weight_mannually.dart';
import 'splash_screen.dart';
//import user preferences form
import 'screens/recommendations_page.dart';

import 'pref_workout.dart'; // Import the pref workout page
import 'gym_equipment.dart'; // Import the gym equipment page
import 'work_place.dart'; // Import the work place page
import 'allset_page.dart'; // Import the all set page
import 'SummaryPage/summary_page.dart';
//import 'SummaryPage/step_tracker_page.dart';
import 'SummaryPage/steps_page.dart';
import 'SummaryPage/measure_weight.dart';
import 'auth_check.dart';
import 'intro_screen.dart';
import 'models/user_model.dart'; // Import your UserModel

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitScale',
      theme: ThemeData.dark(),
      initialRoute: '/', // Ensure this is set to your splash screen
      routes: {
        '/': (context) => const SplashScreen(), // Your custom splash screen
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/select_gender': (context) => const SelectGenderPage(),
        '/set_goal': (context) => const SetGoalPage(),
        '/birth_year': (context) => const BirthYearPage(),
        '/set_height': (context) => const SetHeightPage(),
        '/set_weight': (context) => const SetWeightPage(),
        '/set_weight_mannually': (context) => const SetWeightManuallyPage(),
        //'/act_level': (context) => const ActLevelPage(),
        '/pref_workout': (context) => PrefWorkoutPage(), // Add this route
        '/work_place': (context) => const WorkPlacePage(),
        '/gym_equipment': (context) =>
            const GymEquipmentPage(), // Add this route

        '/all_set': (context) =>
            const AllSetPage(), // Ensure this route is added
        '/summary': (context) => const SummaryPage(), // SelectGenderPage route
        '/steps': (context) => const StepsPage(),
        '/measure_weight': (context) => const MeasureWeightPage(),
        '/workouts': (context) => RecommendationsPage(
              user: UserModel(
                id: 'user_id', // Replace with actual user data
                email: 'user@example.com', // Replace with actual user data
                gender: 'Male', // Replace with actual user data
                goal: 'Build Muscle', // Replace with actual user data
                age: 25, // Replace with actual user data
                weight: 70.0, // Replace with actual user data
                height: 175.0, // Replace with actual user data
                activityLevel:
                    'Moderately Active', // Replace with actual user data
                workoutPlace: 'Gym', // Replace with actual user data
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
