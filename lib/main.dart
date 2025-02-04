import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import
import 'Sign-in-up/signup.dart'; // Import the signup page
import 'Sign-in-up/firstlogin.dart'; // Import the login page
import 'select_gender.dart'; // Import the select gender page
import 'set_goal.dart'; // Import your SetGoalPage
import 'birth_year.dart'; // Import the birth year page
import 'set_height.dart'; // Import the set height page
import 'splash_screen.dart';
import 'pref_workout.dart'; // Import the pref workout page
import 'gym_equipment.dart'; // Import the gym equipment page
import 'work_place.dart'; // Import the work place page
import 'allset_page.dart'; // Import the all set page
import 'SummaryPage/summary_page.dart'; // Import the summary page


void main() {
  WidgetsFlutterBinding.ensureInitialized();  // Add this line
  
  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitScale',
      theme: ThemeData.dark(),
      initialRoute: '/',  // Ensure this is set to your splash screen
      routes: {
        '/': (context) => const SplashScreen(),  // Your custom splash screen
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/select_gender': (context) => const SelectGenderPage(),
        '/set_goal': (context) => const SetGoalPage(),
        '/birth_year': (context) => const BirthYearPage(),
        '/set_height': (context) => const SetHeightPage(),
        '/pref_workout': (context) => PrefWorkoutPage(), // Add this route
        '/work_place': (context) => const WorkPlacePage(),
        '/gym_equipment': (context) => const GymEquipmentPage(), // Add this route
        '/all_set': (context) => const AllSetPage(), // Ensure this route is added
        '/summary': (context) => const SummaryPage(), // Add this route
      },
    );
  }
}

