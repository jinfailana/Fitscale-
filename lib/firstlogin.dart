import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ForgotPasswordPage/forgot_password_page.dart'; // Import the ForgotPasswordPage
import 'services/auth_service.dart';
import 'select_gender.dart';
import 'SummaryPage/summary_page.dart';
import 'screens/loading_screen.dart';
import 'firstlogin.dart';  // Add this import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('en');
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        emailController.text,
        passwordController.text,
      );

      // Check if user has completed setup
      bool setupCompleted = await _authService.hasCompletedSetup(FirebaseAuth.instance.currentUser!.uid);

      if (setupCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SummaryPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SelectGenderPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await GoogleSignIn().signOut(); // Ensure sign-out to allow account selection
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email not signed up yet. Please sign up first.')),
          );
          return;
        }

        // Check if user has completed setup
        bool setupCompleted = await _authService.hasCompletedSetup(user.uid);

        if (setupCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SummaryPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SelectGenderPage()),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 120),
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

                          // Google Login Button
                          OutlinedButton.icon(
                            onPressed: signInWithGoogle,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 20,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading Google logo: $error');
                                return const Icon(Icons.g_mobiledata,
                                    color: Colors.white);
                              },
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
                          const SizedBox(height: 16),

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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'PASSWORD',
                              labelStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
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
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(223, 77, 15, 1.0),
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
                          const SizedBox(height: 16),

                          // Align Create Account and Forgot Password
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Create Account Section
                                Row(
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
                                        Navigator.pushReplacementNamed(
                                            context, '/signup');
                                      },
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color:
                                              Color.fromRGBO(223, 77, 15, 1.0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8), // Adjust spacing between labels

                                // Forgot Password Section - Aligned with "Create an account?"
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero, // Remove default padding
                                    minimumSize: Size.zero, // Remove minimum size constraints
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ForgotPasswordPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 91, 91, 88),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          'assets/Fitscale_LOGO.png',
                          height: screenWidth * 0.4,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading Fitscale logo: $error');
                            return const Icon(Icons.fitness_center,
                                color: Colors.white, size: 80);
                          },
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

class FirstLoginCheck extends StatelessWidget {
  const FirstLoginCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state changed: ${snapshot.data?.uid}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final User? user = snapshot.data;
        if (user == null) {
          print('No user logged in');
          return const LoginPage();
        }

        print('User logged in: ${user.uid}');

        return FutureBuilder<bool>(
          future: _authService.hasCompletedSetup(user.uid),
          builder: (context, setupSnapshot) {
            if (setupSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            final bool isComplete = setupSnapshot.data ?? false;
            print('Setup completion status: $isComplete');

            if (isComplete) {
              print('Setup complete - going to summary page');
              return const SummaryPage();
            } else {
              print('Setup incomplete - starting setup process');
              return const SelectGenderPage();
            }
          },
        );
      },
    );
  }
}
