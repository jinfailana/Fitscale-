import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import the Firebase core package
import 'signup.dart'; // Import the signup page
import 'firstlogin.dart'; // Import the login page
import 'select_gender.dart'; // Import the select gender page

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
      initialRoute: '/signup', // Set the initial route to signup
      routes: {
        '/signup': (context) => const SignupPage(), // SignupPage route
        '/login': (context) => const LoginPage(), // LoginPage route
        '/select_gender': (context) =>
            const SelectGenderPage(), // SelectGenderPage route
      },
    );
  }
}
