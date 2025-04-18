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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData) {
          return const SummaryPage(); // Navigate to Summary page
        }
        // Otherwise, they're not signed in
        return const LoginPage(); // Or your initial page (Login/Signup)
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _setupNavigationChannel();
  }

  void _setupNavigationChannel() {
    const channel = BasicMessageChannel<String>('com.fitscale.app/navigation', StringCodec());
    channel.setMessageHandler((String? message) async {
      if (message == 'navigate_to_splash') {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
      return '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FitScale',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(223, 77, 15, 1.0)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/splash': (context) => const SplashScreen(),
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
      },
    );
  }
}
