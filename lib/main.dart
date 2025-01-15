import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/lib/signup.dart'; // Import the signup page
import 'pages/lib/firstlogin.dart'; // Import the login page
import 'pages/lib/select_gender.dart'; // Import the select gender page

void main() async {
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
      title: 'FitScale App',
      theme: ThemeData.dark(),
      initialRoute: '/signup', // Set the initial route to signup
      routes: {
        '/signup': (context) => const SignupPage(), // SignupPage route
        '/login': (context) => const LoginPage(),   // LoginPage route
        '/select_gender': (context) => const SelectGenderPage(), // SelectGenderPage route
      },
    );
  }
}
