import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' show pi, cos, sin;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../widgets/goal_selection_sheet.dart';
import '../services/step_goal_service.dart';
import '../HistoryPage/history.dart';
import 'summary_page.dart';
import '../navigation/custom_navbar.dart';
import '../utils/custom_page_route.dart';
import '../screens/recommendations_page.dart';
import '../models/user_model.dart';
import 'manage_acc.dart';
import 'package:flutter/rendering.dart' as ui;
import '../services/steps_tracking_service.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> with WidgetsBindingObserver {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  DateTime? _lastStepUpdateTime;
  int _lastSavedSteps = 0;

  // Step tracking service
  final StepsTrackingService _stepsService = StepsTrackingService();

  // Step tracking variables
  int _steps = 0;
  double _percentage = 0;
  int _calories = 0;
  double _distance = 0;
  String _status = 'unknown';
  bool _hasSetGoal = false;
  int _goal = 0;
  bool _goalCompleted = false;
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStepTracking();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentSteps();
    super.dispose();
  }

  Future<void> _initializeStepTracking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return;
      }

      _userId = user.uid;

      // Initialize step tracking service first for immediate updates
      if (!_stepsService.isInitialized) {
        await _stepsService.initialize();
      }

      // Setup real-time listeners for immediate UI updates
      _stepsService.stepsStream.listen((steps) {
        if (mounted) {
          setState(() {
            _steps = steps;
            _updateStats();
          });
        }
      });

      // Setup user document listener for real-time updates
      _setupUserDataListener();

    } catch (e) {
      debugPrint('Error initializing step tracking: $e');
      _showError('Failed to initialize step tracking');
    }
  }

  void _setupUserDataListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel any existing subscription
    _userDataSubscription?.cancel();

    // Listen to user document for real-time updates
    _userDataSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data()!;
      setState(() {
        // Update steps if available
        if (data['current_steps'] != null) {
          _steps = data['current_steps'];
        }

        // Update goal if available
        if (data['step_goal'] != null) {
          _goal = data['step_goal'];
          _hasSetGoal = _goal > 0;
        }

        _updateStats();
      });
    }, onError: (e) {
      debugPrint('Error in user data listener: $e');
    });
  }

  Future<void> _saveCurrentSteps() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      
      // Save to private data collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('private_data')
          .doc('steps')
          .set({
            'current_steps': _steps,
            'last_updated': now,
            'date': DateFormat('yyyy-MM-dd').format(now),
            'user_id': user.uid,
          }, SetOptions(merge: true));

    } catch (e) {
      print('Error saving current steps: $e');
    }
  }

  void _updateStats() {
    if (!mounted) return;

    setState(() {
      // Calculate percentage
      _percentage = _hasSetGoal ? (_steps / _goal * 100).clamp(0, 100) : 0;

      // Calculate calories and distance using the service
      _calories = _stepsService.calculateCaloriesBurned(_steps, null);
      _distance = _stepsService.calculateDistance(_steps);

      // Update goal completion status
      _goalCompleted = _goal > 0 && _steps >= _goal;
    });
  }

  void _showSetGoalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSelectionSheet(
        onGoalSelected: (selectedGoal) async {
          final user = _auth.currentUser;
          if (user == null) return;

          try {
            // Update goal in Firestore
            await _firestore.collection('users').doc(user.uid).update({
              'step_goal': selectedGoal,
              'goal_set_date': FieldValue.serverTimestamp(),
              'user_id': user.uid,
            });

            // Update local state
            if (mounted) {
              setState(() {
                _goal = selectedGoal;
                _hasSetGoal = true;
                _updateStats();
              });
            }

            // Update step service
            await _stepsService.setStepGoal(selectedGoal);
          } catch (e) {
            print('Error setting goal: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to set goal. Please try again.')),
            );
          }
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _loadAndNavigateToRecommendations();
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const HistoryPage(),
          transitionType: TransitionType.rightToLeft,
        ),
      );
    } else if (index == 3) {
      _showProfileModal(context);
    }
  }

  void _showProfileModal(BuildContext context) {
    // Fetch user data from Firestore
    final user = FirebaseAuth.instance.currentUser;
    String username = 'User';
    String email = user?.email ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          // Fetch user data if available
          if (user != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get()
                .then((doc) {
              if (doc.exists) {
                setState(() {
                  username = doc['username'] ?? 'User';
                  email = user.email ?? '';
                });
              }
            }).catchError((e) {
              print('Error fetching user data: $e');
            });
          }

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
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFFDF4D0F),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // User profile card
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the modal first
                      Navigator.push(
                        context,
                        CustomPageRoute(child: const ManageAccPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(28, 28, 30, 1.0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDF4D0F)),
                      ),
                      child: Row(
                        children: [
                          // Profile picture
                          const CircleAvatar(
                            backgroundColor:
                                Color.fromRGBO(223, 77, 15, 0.2),
                            radius: 20,
                            child: Icon(
                              Icons.person,
                              color: Color(0xFFDF4D0F),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // My Device option
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Handle device settings
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(28, 28, 30, 1.0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDF4D0F)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: Color(0xFFDF4D0F),
                            size: 24,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'My Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
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

      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: RecommendationsPage(user: userModel),
          transitionType: TransitionType.rightToLeft,
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

  void _handleSensorError(String sensorName, dynamic error) {
    print('$sensorName error: $error');
    if (mounted) {
      _showError('$sensorName is not available on this device');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDF4D0F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Summary',
          style: TextStyle(
            color: Color(0xFFDF4D0F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Track your steps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (!_hasSetGoal) ...[
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'SET ',
                      style: TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'goal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(flex: 1),
            Text(
              '$_steps',
              style: const TextStyle(
                color: Color.fromRGBO(223, 77, 15, 1.0),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'steps taken',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(340, 170),
                    painter: SemiCircleProgressPainter(
                      percentage: _percentage,
                      color: const Color.fromRGBO(223, 77, 15, 1.0),
                      goal: _goal,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${_percentage.round()}%',
                        style: const TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_hasSetGoal) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showSetGoalBottomSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(223, 77, 15, 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            minimumSize: const Size(100, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text(
                            'SET',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: _calories.toString(),
                  label: 'kcal',
                ),
                _buildStatCard(
                  icon: Icons.place,
                  value: _distance.toStringAsFixed(2),
                  label: 'total distance',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromRGBO(223, 77, 15, 1.0),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color.fromRGBO(223, 77, 15, 1.0),
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
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to show reset confirmation dialog
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        title: const Text(
          'Reset Steps?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset your step count to zero. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _stepsService.resetSteps();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Steps have been reset'),
                  backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFDF4D0F)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reinitialize when app is resumed
      _initializeStepTracking();
    }
  }
}

class SemiCircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final int goal;

  SemiCircleProgressPainter({
    required this.percentage,
    required this.color,
    required this.goal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paint,
    );

    // Draw progress arc if percentage > 0
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        (pi * percentage / 100),
        false,
        progressPaint,
      );
    }

    // Draw tick marks (lines instead of dots)
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Draw labels
    final textStyle = TextStyle(
      color: Colors.grey[400],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Left label (0)
    const leftTextSpan = TextSpan(
      text: '0',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final leftTextPainter = TextPainter(
      text: leftTextSpan,
      textDirection: ui.TextDirection.ltr,
    );
    leftTextPainter.layout();
    leftTextPainter.paint(
      canvas,
      Offset(0, size.height - leftTextPainter.height),
    );

    // Right label (goal)
    final rightTextSpan = TextSpan(
      text: goal.toString(),
      style: textStyle,
    );
    final rightTextPainter = TextPainter(
      text: rightTextSpan,
      textDirection: ui.TextDirection.ltr,
    );
    rightTextPainter.layout();
    rightTextPainter.paint(
      canvas,
      Offset(size.width - rightTextPainter.width,
          size.height - rightTextPainter.height),
    );
  }

  @override
  bool shouldRepaint(SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.goal != goal;
  }
}
