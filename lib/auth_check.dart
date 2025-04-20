import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'firstlogin.dart';
import 'select_gender.dart';
import 'SummaryPage/summary_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/loading_screen.dart';

class AuthCheck extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user == null) return const LoginPage();

          // Check if user has completed setup
          return FutureBuilder<bool>(
            future: _authService.hasCompletedSetup(user.uid),
            builder: (context, setupSnapshot) {
              if (setupSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              // If setup is complete, go to summary/home page
              // If not, start the setup flow
              return setupSnapshot.data == true
                  ? const SummaryPage()
                  : const SelectGenderPage(); // First setup page
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}
