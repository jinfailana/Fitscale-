import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'modals/success_modal.dart';
import 'modals/username_modal.dart';
import 'modals/auth_modal.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? verificationCode;
  final String brevoApiKey =
      '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';

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> sendVerificationEmail(String email) async {
    try {
      verificationCode = (1000 + Random().nextInt(9000)).toString();

      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept': 'application/json',
          'api-key': brevoApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': 'Fitscale', 'email': 'hannstabalanza@gmail.com'},
          'to': [
            {'email': email}
          ],
          'subject': 'Verify your Fitscale account',
          'htmlContent': '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #DF4D0F;">Fitscale Email Verification</h2>
              <p>Your verification code is:</p>
              <h1 style="color: #DF4D0F; font-size: 32px; letter-spacing: 5px;">$verificationCode</h1>
              <p>This code will expire in 10 minutes.</p>
            </div>
          '''
        }),
      );

      if (response.statusCode != 201) {
        throw 'Failed to send verification email: ${response.body}';
      }
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  Future<void> _signup() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Check internet connection first
    bool hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final email = emailController.text.trim();

      // Check if email is registered in your app
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        throw 'This email is already registered';
      }

      // Send verification email
      await sendVerificationEmail(email);

      // Show verification modal
      final isVerified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AuthModal(
          onVerify: (code) async {
            return code == verificationCode;
          },
        ),
      );

      if (isVerified != true) {
        throw 'Email verification failed';
      }

      // Create user account
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      // Store user data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': usernameController.text.trim(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show success modal
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessModal(
          message: 'Account Verified Successfully!',
          onProceed: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signUpWithGoogle() async {
    setState(() => _isLoading = true);

    // Check internet connection first
    bool hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

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

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Check if the user document already exists
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // Use the existing username modal
          final username = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (context) => UsernameInputModal(),
          );

          if (username != null) {
            // Store user information in Firestore
            try {
              await userDoc.set({
                'email': user.email,
                'username': username,
                'signInMethod': 'google',
                'createdAt': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              print('Error storing user data: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to store user data: $e')),
              );
            }

            // Show success modal
            await _showSuccessModal(context);

            // Sign out the user
            await FirebaseAuth.instance.signOut();

            // Redirect to login page
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } catch (e) {
      print('Error signing up with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessModal(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Signed Up Successfully'),
          content: const Text('Your account has been created.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
                              'GET STARTED',
                              style: TextStyle(
                                color: Color.fromRGBO(223, 77, 15, 1.0),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Google Sign Up Button
                          OutlinedButton.icon(
                            onPressed: signUpWithGoogle,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading Google logo: $error');
                                return const Icon(Icons.g_mobiledata,
                                    color: Colors.white);
                              },
                            ),
                            label: const Text(
                              'Sign up with Google',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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

                          // Username Field
                          TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'USERNAME',
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
                                return 'Username is required';
                              } else if (!RegExp(r'^[a-zA-Z]+$')
                                  .hasMatch(value)) {
                                return 'Username must contain only alphabets';
                              }
                              return null;
                            },
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
                              if (!value.endsWith('@gmail.com')) {
                                return 'Email must end with @gmail.com';
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
                              } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                                  .hasMatch(value)) {
                                return 'Password must contain a special character';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'CONFIRM PASSWORD',
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
                                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              } else if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Continue Button
                          ElevatedButton(
                            onPressed: _signup,
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

                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  'Already have an account? ',
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
                                        context, '/login');
                                  },
                                  child: const Text(
                                    'Sign in',
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
                    Positioned(
                      top: -15,
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
