import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool fromNotification;
  const SplashScreen({super.key, this.fromNotification = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // If coming from notification, always go to intro screen
      if (widget.fromNotification) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (currentUser != null) {
        // User is logged in, check if they have completed onboarding
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists) {
          // User exists in Firestore, go to summary page
          Navigator.pushReplacementNamed(context, '/summary');
        } else {
          // User document doesn't exist, go to login
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // No user logged in, go to intro screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
      }
    } catch (e) {
      print('Error in splash screen: $e');
      // In case of any error, safely navigate to intro screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333232),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Fitscale_LOGO.png',
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading logo: $error');
                return const CircularProgressIndicator(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                );
              },
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color.fromRGBO(223, 77, 15, 1.0),
            ),
          ],
        ),
      ),
    );
  }
} 