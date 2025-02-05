import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the locale for Firebase Authentication
    FirebaseAuth.instance.setLanguageCode('en');
  }

  Future<void> signInWithEmail() async {
    if (!formKey.currentState!.validate()) return;

    try {
      // Attempt to sign in
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Verify user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account not found. Please sign up first.')),
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/select_gender');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Google
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Verify user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Google account not registered. Please sign up first.')),
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/select_gender');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            clipBehavior: Clip.none, // Allow logo to overflow
            children: [
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120), // Spacer for the logo
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'EMAIL',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PASSWORD',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        } else if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Password must contain an uppercase letter';
                        } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'Password must contain a lowercase letter';
                        } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Password must contain a number';
                        } else if (!RegExp(r'[!@#\\$%^&*(),.?":{}|<>]')
                            .hasMatch(value)) {
                          return 'Password must contain a special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.play_arrow,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white54)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Login Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        await signInWithGoogle();
                      },
                      icon: Image.asset(
                        'assets/google_logo.png', // Replace with your Google logo path
                        height: 20,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    // Create Account Section
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Create an account? ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to the Signup Page
                              Navigator.pushReplacementNamed(
                                  context, '/signup');
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Color.fromRGBO(223, 77, 15, 1.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Logo on top of the form
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/Fitscale_LOGO.png',
                    height: 160,
                    fit: BoxFit.contain, // Ensures the image scales well
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
