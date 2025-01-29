import 'package:flutter/material.dart';
import 'signup.dart'; // Import the signup page
import 'firstlogin.dart'; // Import the login page
import 'select_gender.dart'; // Import the select gender page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
