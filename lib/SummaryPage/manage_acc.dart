import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';
import 'dart:math';
import 'dart:isolate';
import '../navigation/custom_navbar.dart';
import '../utils/custom_page_route.dart';
import '../screens/recommendations_page.dart';
import '../HistoryPage/history.dart';
import '../models/user_model.dart';
import '../firstlogin.dart';

class ManageAccPage extends StatefulWidget {
  final VoidCallback? onClose;

  const ManageAccPage({super.key, this.onClose});

  @override
  State<ManageAccPage> createState() => _ManageAccPageState();
}

class _ManageAccPageState extends State<ManageAccPage> {
  String username = '';
  String signInMethod = '';
  late final WorkoutHistoryService _historyService;
  int _selectedIndex = 3;
  List<WorkoutHistory>? _cachedWorkoutHistory;
  DateTime? _lastFetchTime;
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _historyService = WorkoutHistoryService(userId: user.uid);
    }
    _initializeData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!_mounted) return;

    try {
      await Future.wait([
        _fetchUserData(),
        _loadWorkoutHistory(),
      ]);
    } catch (e) {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutHistory() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final workouts = await _fetchWorkoutHistory();
      if (!_mounted) return;

      setState(() {
        _cachedWorkoutHistory = workouts;
        _isLoading = false;
      });
    } catch (e) {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'] ?? 'User';
            signInMethod = userDoc['signInMethod'] ?? 'email';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchUserGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return {};

      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'fitnessGoal': data['fitnessGoal'] ?? '',
        'workoutFrequency': data['workoutFrequency'] ?? 0,
        'workoutDuration': data['workoutDuration'] ?? 0,
      };
    } catch (e) {
      print('Error fetching user goals: $e');
      return {};
    }
  }

  Widget _buildProgressChart() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDF4D0F)),
      );
    }

    if (_cachedWorkoutHistory == null || _cachedWorkoutHistory!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text(
              'No workout data available yet',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Complete workouts to track progress',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final workouts = _cachedWorkoutHistory!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Workout Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: OptimizedProgressChart(workouts: workouts),
        ),
        const SizedBox(height: 24),
        // Progress Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total\nWorkouts',
                  workouts.length.toString(),
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${workouts.where((w) => w.isCompleted).length}/${workouts.length}',
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg. Sets',
                  (workouts.fold<int>(0, (sum, w) => sum + w.setsCompleted) /
                          workouts.length)
                      .round()
                      .toString(),
                  Icons.repeat,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateWeekProgress(List<WorkoutHistory> weekWorkouts) {
    if (weekWorkouts.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (var workout in weekWorkouts) {
      if (workout.progress > 0) {
        totalProgress += workout.progress;
      } else {
        final setProgress = workout.totalSets > 0
            ? (workout.setsCompleted / workout.totalSets)
            : 0.0;
        final completionProgress = workout.isCompleted ? 1.0 : 0.0;
        totalProgress += (setProgress * 0.7 + completionProgress * 0.3);
      }
    }

    return (totalProgress / weekWorkouts.length).clamp(0.0, 100.0);
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDF4D0F).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFFDF4D0F),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<WorkoutHistory>> _fetchWorkoutHistory() async {
    // Check if we have cached data that's less than 5 minutes old
    if (_cachedWorkoutHistory != null && _lastFetchTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetchTime!).inMinutes < 5) {
        return _cachedWorkoutHistory!;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Get only the last 30 days of data
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .where('date',
              isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
          .orderBy('date', descending: false)
          .get();

      final workouts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutHistory(
          id: doc.id,
          workoutName: data['workoutName'] ?? '',
          exerciseName: data['exerciseName'] ?? '',
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          setsCompleted: data['setsCompleted'] ?? 0,
          totalSets: data['totalSets'] ?? 0,
          repsPerSet: data['repsPerSet'] ?? 0,
          status: data['status'] ?? 'in_progress',
          duration: data['duration'] ?? 0,
          musclesWorked: List<String>.from(data['musclesWorked'] ?? []),
          notes: data['notes'] ?? '',
          weight: (data['weight'] ?? 0.0).toDouble(),
          caloriesBurned: (data['caloriesBurned'] ?? 0.0).toDouble(),
          exerciseDetails:
              Map<String, dynamic>.from(data['exerciseDetails'] ?? {}),
          difficulty: data['difficulty'] ?? 'medium',
          restBetweenSets: data['restBetweenSets'] ?? 60,
          progress: (data['progress'] ?? 0.0).toDouble(),
          goal: data['goal'] ?? '',
        );
      }).toList();

      // Cache the results
      _cachedWorkoutHistory = workouts;
      _lastFetchTime = DateTime.now();

      return workouts;
    } catch (e) {
      return _cachedWorkoutHistory ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildAccountOption(context, 'Name', username),
            const SizedBox(height: 16),
            _buildAccountOption(context, 'Change Password', ''),
            const SizedBox(height: 24),
            // Workout Progress Card
            Card(
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workout Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDF4D0F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Last 30 Days',
                            style: TextStyle(
                              color: Color(0xFFDF4D0F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your cumulative progress over time',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProgressChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showLogoutConfirmationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDF4D0F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        showProfileModal: _showProfileModal,
        loadAndNavigateToRecommendations: _loadAndNavigateToRecommendations,
      ),
    );
  }

  Widget _buildAccountOption(
      BuildContext context, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        if (title == 'Name') {
          _showChangeUsernameDialog(context);
        } else if (title == 'Change Password') {
          _handleChangePassword(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _showChangeUsernameDialog(BuildContext context) {
    final usernameController = TextEditingController(text: username);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(28, 28, 30, 1.0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDF4D0F), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDF4D0F)),
                    ),
                    child: TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(60, 60, 62, 1.0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: Color(0xFFDF4D0F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final newUsername = usernameController.text.trim();
                            if (newUsername.isNotEmpty &&
                                newUsername != username) {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({'username': newUsername});
                                  setState(() {
                                    username = newUsername;
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Username changed successfully.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error changing username: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to change username: $e'),
                                  ),
                                );
                              }
                            } else if (newUsername.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username cannot be empty'),
                                ),
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDF4D0F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'SAVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleChangePassword(BuildContext context) {
    if (signInMethod == 'google') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changes for Google accounts must be done through Google.',
          ),
        ),
      );
    } else {
      _showChangePasswordDialog(context);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();

    // Add state variables to track password visibility
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    // Create a form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(28, 28, 30, 1.0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDF4D0F), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Current Password Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDF4D0F)),
                        ),
                        child: TextFormField(
                          controller: currentPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Current Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  isCurrentPasswordVisible =
                                      !isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return const Text(
                                'Required',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // New Password Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDF4D0F)),
                        ),
                        child: TextFormField(
                          controller: newPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !isNewPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isNewPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  isNewPasswordVisible = !isNewPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return const Text(
                                'Password is required',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (value.length < 8) {
                              return const Text(
                                'Must be at least 8 characters',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return const Text(
                                'Must contain uppercase',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return const Text(
                                'Must contain lowercase',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return const Text(
                                'Must contain number',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                                .hasMatch(value)) {
                              return const Text(
                                'Must contain special character',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirm Password Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDF4D0F)),
                        ),
                        child: TextFormField(
                          controller: confirmNewPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return const Text(
                                'Required',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            } else if (value != newPasswordController.text) {
                              return const Text(
                                'Passwords don\'t match',
                                style:
                                    TextStyle(fontSize: 5.0, color: Colors.red),
                              ).data;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(60, 60, 62, 1.0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      color: Color(0xFFDF4D0F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                // Validate the form
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final currentPassword =
                                    currentPasswordController.text.trim();
                                final newPassword =
                                    newPasswordController.text.trim();
                                final confirmNewPassword =
                                    confirmNewPasswordController.text.trim();

                                try {
                                  // Re-authenticate the user
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final cred = EmailAuthProvider.credential(
                                      email: user!.email!,
                                      password: currentPassword);

                                  await user.reauthenticateWithCredential(cred);

                                  // Update the password
                                  await user.updatePassword(newPassword);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Password changed successfully.'),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error changing password: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to change password: $e'),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDF4D0F),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'SAVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(223, 77, 15, 1.0)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();

                  // Close the dialog
                  Navigator.pop(context);

                  // Navigate to login page and clear all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    CustomPageRoute(
                      child: const FirstLoginCheck(),
                      transitionType: TransitionType.fade,
                    ),
                    (route) =>
                        false, // This predicate ensures all previous routes are removed
                  );
                } catch (e) {
                  print('Error signing out: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FlSpot> _createDataPoints(List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) return [];

    // Get date range (last 30 days)
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(const Duration(days: 29));

    // Pre-calculate the number of days and step size
    final int totalDays = 30;
    final int step = (totalDays / OptimizedProgressChart.maxDataPoints).ceil();

    // Create fixed-size arrays for better memory management
    final List<DateTime> dates = List.generate(
        OptimizedProgressChart.maxDataPoints,
        (index) => startDate.add(Duration(days: index * step)));

    final List<double> values =
        List.filled(OptimizedProgressChart.maxDataPoints, 0.0);

    // Group workouts by date more efficiently
    final workoutsByDate = <DateTime, List<WorkoutHistory>>{};
    for (var workout in workouts) {
      final date = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      workoutsByDate.putIfAbsent(date, () => []).add(workout);
    }

    // Calculate progress with fixed intervals
    double cumulativeProgress = 0;
    for (var i = 0; i < dates.length; i++) {
      final currentDate = dates[i];

      if (workoutsByDate.containsKey(currentDate)) {
        final dailyWorkouts = workoutsByDate[currentDate]!;
        double dailyProgress = 0;

        for (var workout in dailyWorkouts) {
          if (workout.progress > 0) {
            dailyProgress += workout.progress;
          } else {
            final setProgress = workout.totalSets > 0
                ? (workout.setsCompleted / workout.totalSets)
                : 0.0;
            final completionProgress = workout.isCompleted ? 1.0 : 0.0;
            dailyProgress += (setProgress * 0.7 + completionProgress * 0.3);
          }
        }

        dailyProgress = dailyProgress / dailyWorkouts.length;
        cumulativeProgress = (cumulativeProgress * 0.7) + (dailyProgress * 0.3);
      } else {
        cumulativeProgress *= 0.95;
      }

      values[i] = cumulativeProgress.clamp(0.0, 100.0);
    }

    // Create spots directly without intermediate collections
    return List.generate(
      OptimizedProgressChart.maxDataPoints,
      (i) => FlSpot(
        dates[i].millisecondsSinceEpoch.toDouble(),
        values[i],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index != 3) {
      // If not on the current "Me" tab
      Navigator.pop(context); // Pop the current page first

      if (index == 0) {
        // Navigate to SummaryPage is handled by popping back
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          CustomPageRoute(child: const HistoryPage()),
        );
      }
    }
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(28, 28, 30, 1.0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(right: 75.0),
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileModalOption(
                  Icons.person,
                  username,
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    // Already on account page, no need to navigate
                  },
                ),
                const SizedBox(height: 10),
                _buildProfileModalOption(
                  Icons.devices,
                  'My Device',
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    // Handle device settings navigation if needed
                  },
                ),
                const SizedBox(height: 10),
                _buildProfileModalOption(
                  Icons.logout,
                  'Log Out',
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileModalOption(IconData icon, String title, String subtitle,
      {required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFDF4D0F)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAndNavigateToRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please log in to view recommendations')),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print('User document does not exist');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Validate required date fields
      if (userData['createdAt'] == null || userData['updatedAt'] == null) {
        print('Missing date fields in user data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user profile data')),
        );
        return;
      }

      final userModel = UserModel(
        id: user.uid,
        email: userData['email'] ?? '',
        gender: userData['gender'],
        goal: userData['goal'],
        age: userData['age'],
        weight: userData['weight'] != null
            ? (userData['weight'] as num).toDouble()
            : null,
        height: userData['height'] != null
            ? (userData['height'] as num).toDouble()
            : null,
        activityLevel: userData['activityLevel'],
        workoutPlace: userData['workoutPlace'],
        preferredWorkouts: userData['preferredWorkouts'] != null
            ? List<String>.from(userData['preferredWorkouts'])
            : null,
        gymEquipment: userData['gymEquipment'] != null
            ? List<String>.from(userData['gymEquipment'])
            : null,
        setupCompleted: userData['setupCompleted'] ?? false,
        currentSetupStep: userData['currentSetupStep'] ?? 'registered',
        createdAt: userData['createdAt'] is String
            ? DateTime.parse(userData['createdAt'])
            : (userData['createdAt'] as Timestamp).toDate(),
        updatedAt: userData['updatedAt'] is String
            ? DateTime.parse(userData['updatedAt'])
            : (userData['updatedAt'] as Timestamp).toDate(),
      );

      Navigator.push(
        context,
        CustomPageRoute(
          child: RecommendationsPage(user: userModel),
        ),
      );
    } catch (e, stackTrace) {
      print('Error loading recommendations: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load recommendations: ${e.toString()}')),
      );
    }
  }
}

class DailyProgress {
  final List<WorkoutHistory> workouts;
  final int totalDuration;
  final int completedSets;

  DailyProgress({
    required this.workouts,
    required this.totalDuration,
    required this.completedSets,
  });
}

class OptimizedProgressChart extends StatefulWidget {
  final List<WorkoutHistory> workouts;
  static const int maxDataPoints = 10; // Limit total data points

  const OptimizedProgressChart({
    Key? key,
    required this.workouts,
  }) : super(key: key);

  @override
  State<OptimizedProgressChart> createState() => _OptimizedProgressChartState();
}

class _OptimizedProgressChartState extends State<OptimizedProgressChart> {
  List<FlSpot>? _spots;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() {
    Future.microtask(() {
      if (!mounted) return;

      final spots = _createDataPoints(widget.workouts);
      if (mounted) {
        setState(() {
          _spots = spots;
          _isLoading = false;
        });
      }
    });
  }

  List<FlSpot> _createDataPoints(List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) return [];

    // Get date range (last 30 days)
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(const Duration(days: 29));

    // Pre-calculate the number of days and step size
    final int totalDays = 30;
    final int step = (totalDays / OptimizedProgressChart.maxDataPoints).ceil();

    // Create fixed-size arrays for better memory management
    final List<DateTime> dates = List.generate(
        OptimizedProgressChart.maxDataPoints,
        (index) => startDate.add(Duration(days: index * step)));

    final List<double> values =
        List.filled(OptimizedProgressChart.maxDataPoints, 0.0);

    // Group workouts by date more efficiently
    final workoutsByDate = <DateTime, List<WorkoutHistory>>{};
    for (var workout in workouts) {
      final date = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      workoutsByDate.putIfAbsent(date, () => []).add(workout);
    }

    // Calculate progress with fixed intervals
    double cumulativeProgress = 0;
    for (var i = 0; i < dates.length; i++) {
      final currentDate = dates[i];

      if (workoutsByDate.containsKey(currentDate)) {
        final dailyWorkouts = workoutsByDate[currentDate]!;
        double dailyProgress = 0;

        for (var workout in dailyWorkouts) {
          if (workout.progress > 0) {
            dailyProgress += workout.progress;
          } else {
            final setProgress = workout.totalSets > 0
                ? (workout.setsCompleted / workout.totalSets)
                : 0.0;
            final completionProgress = workout.isCompleted ? 1.0 : 0.0;
            dailyProgress += (setProgress * 0.7 + completionProgress * 0.3);
          }
        }

        dailyProgress = dailyProgress / dailyWorkouts.length;
        cumulativeProgress = (cumulativeProgress * 0.7) + (dailyProgress * 0.3);
      } else {
        cumulativeProgress *= 0.95;
      }

      values[i] = cumulativeProgress.clamp(0.0, 100.0);
    }

    // Create spots directly without intermediate collections
    return List.generate(
      OptimizedProgressChart.maxDataPoints,
      (i) => FlSpot(
        dates[i].millisecondsSinceEpoch.toDouble(),
        values[i],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _spots == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDF4D0F)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: _spots!.first.x,
          maxX: _spots!.last.x,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: _spots!,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDF4D0F).withOpacity(0.5),
                  const Color(0xFFDF4D0F),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) {
                  final index = barData.spots.indexOf(spot);
                  return index == 0 || index == barData.spots.length - 1;
                },
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFDF4D0F),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFDF4D0F).withOpacity(0.3),
                    const Color(0xFFDF4D0F).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF1A1A1A),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Progress: ${barSpot.y.toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFDF4D0F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: const Color(0xFFDF4D0F),
                    strokeWidth: 2,
                    dashArray: [5, 5],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFFDF4D0F),
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
