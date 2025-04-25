import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';
import 'dart:math';
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
          child: OptimizedProgressChart(),
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

  // Add a stream builder for real-time stats
  Widget _buildWorkoutStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .orderBy('date', descending: true)
          .limit(30) // Last 30 days
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stats'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data!.docs
            .map((doc) => WorkoutHistory.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList();

        // Calculate stats
        final totalWorkouts = workouts.length;
        final completedWorkouts = workouts.where((w) => w.isCompleted).length;
        final totalSets =
            workouts.fold<int>(0, (sum, w) => sum + w.setsCompleted);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              'Total\nWorkouts',
              totalWorkouts.toString(),
              Icons.fitness_center,
            ),
            _buildStatCard(
              'Completed',
              '$completedWorkouts/$totalWorkouts',
              Icons.check_circle_outline,
            ),
            _buildStatCard(
              'Avg. Sets',
              totalWorkouts > 0
                  ? (totalSets / totalWorkouts).toStringAsFixed(1)
                  : '0',
              Icons.repeat,
            ),
          ],
        );
      },
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
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDF4D0F).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Color(0xFFDF4D0F),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your workout completion and set progress',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: OptimizedProgressChart(),
                    ),
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

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Always start with a point at the beginning of the day
    List<FlSpot> spots = [
      FlSpot(startOfDay.millisecondsSinceEpoch.toDouble(), 0)
    ];

    // Get total number of workouts in "My Workouts" for today
    Future<int> getTotalWorkouts() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('my_workouts')
            .get();

        return querySnapshot.docs.length;
      } catch (e) {
        print('Error getting total workouts: $e');
        return 0;
      }
    }

    // Filter and sort today's workouts
    final todayWorkouts = workouts.where((workout) {
      final workoutDate = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      return workoutDate.isAtSameMomentAs(startOfDay);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate progress based on completed workouts
    int totalWorkoutsToComplete = 0;
    getTotalWorkouts().then((total) {
      totalWorkoutsToComplete = total > 0 ? total : 1; // Avoid division by zero
    });

    // Add points for each workout
    for (var workout in todayWorkouts) {
      double progress = 0.0;

      // Calculate progress as a percentage of completed workouts
      final completedWorkouts = todayWorkouts
          .where((w) => w.date.isBefore(workout.date) && w.isCompleted)
          .length;

      if (totalWorkoutsToComplete > 0) {
        progress = (completedWorkouts / totalWorkoutsToComplete) * 100;
      }

      // Add individual workout progress
      if (workout.isCompleted) {
        progress += (100.0 / totalWorkoutsToComplete);
      } else if (workout.totalSets > 0) {
        // For incomplete workouts, add partial progress based on completed sets
        final workoutProgress = (workout.setsCompleted / workout.totalSets) *
            (100.0 / totalWorkoutsToComplete);
        progress += workoutProgress;
      }

      // Ensure progress doesn't exceed 100%
      progress = progress.clamp(0.0, 100.0);

      spots.add(FlSpot(
        workout.date.millisecondsSinceEpoch.toDouble(),
        progress,
      ));
    }

    // Add current time point if no workouts or last workout was earlier
    if (todayWorkouts.isEmpty ||
        (todayWorkouts.isNotEmpty && todayWorkouts.last.date.isBefore(now))) {
      spots.add(FlSpot(
        now.millisecondsSinceEpoch.toDouble(),
        spots.isEmpty ? 0 : spots.last.y,
      ));
    }

    return spots;
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
  const OptimizedProgressChart({Key? key}) : super(key: key);

  @override
  State<OptimizedProgressChart> createState() => _OptimizedProgressChartState();
}

class _OptimizedProgressChartState extends State<OptimizedProgressChart>
    with SingleTickerProviderStateMixin {
  List<FlSpot>? _workoutSpots;
  List<FlSpot>? _setSpots;
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _workoutSubscription;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _totalWorkoutsToComplete = 0;
  int _totalSetsToComplete = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeData() async {
    await _fetchTotalWorkouts();
    _setupWorkoutListener();

    // Set up periodic updates every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchTotalWorkouts();
      }
    });
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTotalWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('my_workouts')
          .get();

      if (!mounted) return;

      setState(() {
        _totalWorkoutsToComplete = querySnapshot.docs.length;
        // Calculate total sets based on actual workout data
        _totalSetsToComplete = querySnapshot.docs.fold(0, (sum, doc) {
          final data = doc.data();
          return sum +
              (data['totalSets'] as int? ??
                  3); // Default to 3 sets if not specified
        });
      });
    } catch (e) {
      print('Error getting total workouts: $e');
    }
  }

  void _setupWorkoutListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Cancel existing subscription if any
    _workoutSubscription?.cancel();

    // Listen to real-time updates with server timestamp
    _workoutSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workout_history')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .orderBy('date', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final workouts = snapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutHistory.fromMap({...data, 'id': doc.id});
      }).toList();

      setState(() {
        final points = _createDataPoints(workouts);
        _workoutSpots = points['workoutSpots'];
        _setSpots = points['setSpots'];
        _isLoading = false;
      });

      // Reset and start animation for smooth transitions
      _animationController.reset();
      _animationController.forward();
    }, onError: (error) {
      print('Error in workout listener: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Map<String, List<FlSpot>> _createDataPoints(List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) {
      return {
        'workoutSpots': [],
        'setSpots': [],
      };
    }

    final now = DateTime.now();

    // Filter and sort today's workouts
    final todayWorkouts = workouts..sort((a, b) => a.date.compareTo(b.date));

    if (todayWorkouts.isEmpty) {
      return {
        'workoutSpots': [],
        'setSpots': [],
      };
    }

    // Get the first actual workout time
    final firstWorkoutTime = todayWorkouts.first.date;

    List<FlSpot> workoutSpots = [];
    List<FlSpot> setSpots = [];

    // Add initial point
    workoutSpots
        .add(FlSpot(firstWorkoutTime.millisecondsSinceEpoch.toDouble(), 0));
    setSpots.add(FlSpot(firstWorkoutTime.millisecondsSinceEpoch.toDouble(), 0));

    // Track progress
    double workoutProgress = 0.0;
    int totalSetsCompleted = 0;
    int totalSetsPossible = 0;
    DateTime? lastWorkoutTime;

    // First pass: Calculate total possible sets
    for (var workout in todayWorkouts) {
      totalSetsPossible += workout.totalSets;
    }

    // Ensure we have valid denominators
    final effectiveTotalWorkouts = _totalWorkoutsToComplete > 0
        ? _totalWorkoutsToComplete
        : todayWorkouts.length;
    final effectiveTotalSets =
        totalSetsPossible > 0 ? totalSetsPossible : _totalSetsToComplete;

    // Process each workout
    for (var workout in todayWorkouts) {
      final timestamp = workout.date.millisecondsSinceEpoch.toDouble();

      // Add intermediate points for smoother curves if there's a gap
      if (lastWorkoutTime != null) {
        final timeDiff = workout.date.difference(lastWorkoutTime).inMinutes;
        if (timeDiff > 5) {
          // Add a point shortly after the last workout
          final afterLastWorkout =
              lastWorkoutTime.add(const Duration(minutes: 1));
          workoutSpots.add(FlSpot(
              afterLastWorkout.millisecondsSinceEpoch.toDouble(),
              workoutProgress));

          // Add a point just before the current workout
          final beforeCurrentWorkout =
              workout.date.subtract(const Duration(minutes: 1));
          workoutSpots.add(FlSpot(
              beforeCurrentWorkout.millisecondsSinceEpoch.toDouble(),
              workoutProgress));
        }
      }

      // Calculate workout progress
      if (workout.isCompleted) {
        // Each completed workout contributes equally to the total progress
        workoutProgress =
            ((workoutSpots.length + 1) / effectiveTotalWorkouts) * 100;
      } else if (workout.totalSets > 0) {
        // For incomplete workouts, add partial progress based on completed sets
        final partialProgress = (workout.setsCompleted / workout.totalSets) *
            (100 / effectiveTotalWorkouts);
        workoutProgress += partialProgress;
      }
      workoutProgress = workoutProgress.clamp(0.0, 100.0);

      // Add workout progress point
      workoutSpots.add(FlSpot(timestamp, workoutProgress));

      // Calculate and add set progress points
      if (workout.totalSets > 0) {
        // Add points for each set completed
        for (int i = 1; i <= workout.setsCompleted; i++) {
          totalSetsCompleted++;
          // Calculate set progress as a percentage of total possible sets
          final setProgress = (totalSetsCompleted / effectiveTotalSets) * 100;

          // Calculate time for this set (distribute sets across workout duration)
          final setTime = workout.date.add(Duration(
            minutes: (i * 2), // Assume each set takes about 2 minutes
          ));

          setSpots.add(FlSpot(setTime.millisecondsSinceEpoch.toDouble(),
              setProgress.clamp(0.0, 100.0)));
        }
      }

      lastWorkoutTime = workout.date;
    }

    // Add current time point if there's progress
    if (todayWorkouts.isNotEmpty && lastWorkoutTime != null) {
      final timeSinceLastWorkout = now.difference(lastWorkoutTime).inMinutes;

      if (timeSinceLastWorkout > 1) {
        // Add a smooth transition point after the last workout
        final afterLastWorkout =
            lastWorkoutTime.add(const Duration(minutes: 1));
        workoutSpots.add(FlSpot(
            afterLastWorkout.millisecondsSinceEpoch.toDouble(),
            workoutProgress));
        setSpots.add(FlSpot(afterLastWorkout.millisecondsSinceEpoch.toDouble(),
            setSpots.last.y));

        // Add current point
        final currentTimestamp = now.millisecondsSinceEpoch.toDouble();
        workoutSpots.add(FlSpot(currentTimestamp, workoutProgress));
        setSpots.add(FlSpot(currentTimestamp, setSpots.last.y));
      }
    }

    return {
      'workoutSpots': workoutSpots,
      'setSpots': setSpots,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDF4D0F)),
      );
    }

    if (_workoutSpots == null || _workoutSpots!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text(
              'No workout data available today',
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

    // Calculate time range and intervals
    final firstSpotTime = _workoutSpots!.first.x;
    final lastSpotTime = _workoutSpots!.last.x;
    final timeSpan = lastSpotTime - firstSpotTime;

    // Add 20% padding to the time range
    final paddingTime = timeSpan * 0.2;
    final minX = firstSpotTime - paddingTime;
    final maxX = lastSpotTime + paddingTime;

    // Use 5-minute intervals for grid lines (300,000 milliseconds)
    const interval = 300000.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Workout Progress', const Color(0xFFDF4D0F)),
              const SizedBox(width: 24),
              _buildLegendItem('Sets Completed', Colors.green),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 0.5,
                    ),
                    checkToShowVerticalLine: (value) {
                      return _workoutSpots!
                          .any((spot) => (spot.x - value).abs() < interval / 2);
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
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          final hasNearbyPoint = _workoutSpots!.any(
                              (spot) => (spot.x - value).abs() < interval / 2);

                          if (!hasNearbyPoint) {
                            return const SizedBox.shrink();
                          }

                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
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
                        reservedSize: 35,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _workoutSpots!
                          .map((spot) => FlSpot(
                                spot.x,
                                spot.y * _animation.value,
                              ))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFDF4D0F),
                      barWidth: 3.0,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4.0,
                          color: const Color(0xFFDF4D0F),
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFDF4D0F).withOpacity(0.08),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFDF4D0F).withOpacity(0.15),
                            const Color(0xFFDF4D0F).withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: _setSpots!
                          .map((spot) => FlSpot(
                                spot.x,
                                spot.y * _animation.value,
                              ))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.green.withOpacity(0.8),
                      barWidth: 2.0,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.0,
                          color: Colors.green.withOpacity(0.8),
                          strokeWidth: 1.0,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.05),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.01),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
