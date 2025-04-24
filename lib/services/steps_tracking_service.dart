import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'user_service.dart';

/// Singleton service for tracking steps throughout the app lifecycle
/// This service stays alive as long as the app is running
class StepsTrackingService {
  // Singleton instance
  static final StepsTrackingService _instance = StepsTrackingService._internal();
  factory StepsTrackingService() => _instance;
  StepsTrackingService._internal();

  // Services
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Pedometer streams
  StreamSubscription<StepCount>? _stepCountSubscription;
  
  // Step tracking variables
  int _steps = 0;
  int _initialSteps = 0;
  bool _isFirstReading = true;
  int _goal = 0;
  bool _goalCompleted = false;
  DateTime? _lastStepTime;
  int _lastStepCount = 0;
  bool _isInitialized = false;
  DateTime? _lastFirestoreUpdate;
  
  // Timer for periodic updates
  Timer? _updateTimer;
  Timer? _syncTimer;
  
  // Getters
  int get currentSteps => _steps;
  int get goalSteps => _goal;
  bool get goalCompleted => _goalCompleted;
  double get goalPercentage => _goal > 0 ? (_steps / _goal * 100).clamp(0.0, 100.0) : 0.0;
  bool get isInitialized => _isInitialized;
  
  // Create a stream controller for real-time updates
  final StreamController<int> _stepsController = StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;
  
  // Callbacks for UI updates
  Function(int)? onStepsChanged;
  Function(int)? onGoalChanged;
  Function(bool, {int steps, int goal})? onGoalCompleted;
  
  /// Initialize the step tracking service
  Future<void> initialize() async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return;
      }

      // Only initialize once
      if (_isInitialized) return;
      
      // Load user data first
      await _loadUserData();
      
      // Then initialize pedometer
      await _initializePedometerStream();
      
      // Set up periodic updates every 2 seconds to ensure UI stays fresh
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        // Emit current steps to stream
        _stepsController.add(_steps);
        
        // Also call the callback for any existing listeners
        if (onStepsChanged != null) {
          onStepsChanged!(_steps);
        }
      });
      
      // Sync with Firestore every 30 seconds
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        // Only update if enough time has passed since last update
        final now = DateTime.now();
        final lastUpdate = _lastFirestoreUpdate ?? DateTime.now().subtract(const Duration(minutes: 5));
        if (now.difference(lastUpdate).inMinutes >= 5) {
          _updateFirestoreSteps();
        }
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing step tracking: $e');
    }
  }
  
  /// Helper method to save steps to Firestore
  void _saveStepsToFirestore() {
    _saveStepsAsync(_steps).then((_) {
      // Optional: Handle successful save
    }).catchError((error) {
      debugPrint('Error saving steps to Firestore: $error');
    });
  }
  
  /// Load user data, including current steps and goals
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get current date
      final today = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(today);
      
      // Check if we need to reset steps for a new day
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('${user.uid}_last_step_date');
      
      if (lastDate != formattedDate) {
        // It's a new day, save yesterday's data before resetting
        final yesterdaySteps = prefs.getInt('${user.uid}_current_steps') ?? 0;
        if (yesterdaySteps > 0) {
          await _saveStepHistory(yesterdaySteps, lastDate);
        }
        
        // Reset steps for new day
        _steps = 0;
        await prefs.setInt('${user.uid}_current_steps', 0);
        await prefs.setString('${user.uid}_last_step_date', formattedDate);
        
        // Reset Firestore steps for new day
        await _updateFirestoreSteps();
      } else {
        // Load today's steps from Firebase
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _steps = data['current_steps'] ?? 0;
          debugPrint('Loaded steps from Firebase: $_steps');
        } else {
          // If no Firestore data, try to load from cache
          _steps = prefs.getInt('${user.uid}_current_steps') ?? 0;
          debugPrint('Loaded steps from cache: $_steps');
        }
      }
      
      // Get user's step goal
      final stepData = await _userService.getCurrentStepData();
      _goal = stepData['step_goal'] ?? 0;
      
      // Update UI immediately
      _stepsController.add(_steps);
      if (onStepsChanged != null) {
        onStepsChanged!(_steps);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  
  /// Check if this is a first-time user
  Future<bool> _checkIfFirstTimeUser(String userId) async {
    try {
      // Check if the user has any existing step data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return true;
      
      final userData = userDoc.data();
      if (userData == null) return true;
      
      // Check if current_steps field exists and has a value
      if (!userData.containsKey('current_steps')) {
        return true;
      }
      
      // Check when the user was created
      final createdAt = userData['createdAt'] as Timestamp?;
      if (createdAt == null) return false;
      
      // Consider users created within the last hour as new users
      final now = DateTime.now();
      final createTime = createdAt.toDate();
      final difference = now.difference(createTime);
      
      return difference.inHours < 1;
    } catch (e) {
      debugPrint('Error checking if first time user: $e');
      return false;
    }
  }

  /// Resume the step tracking service
  Future<void> resume() async {
    // If not initialized, do full initialization
    if (!_isInitialized) {
      await initialize();
      return;
    }
    
    // If already initialized but pedometer subscription was canceled, reconnect it
    if (_stepCountSubscription == null) {
      await _initializePedometerStream();
    }
    
    // Restart timers if they were stopped
    if (_updateTimer == null || !_updateTimer!.isActive) {
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _stepsController.add(_steps);
        if (onStepsChanged != null) {
          onStepsChanged!(_steps);
        }
      });
    }
    
    if (_syncTimer == null || !_syncTimer!.isActive) {
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateFirestoreSteps();
      });
    }
  }
  
  /// Explicitly reset steps for new users
  Future<void> resetStepsForNewUser(String userId) async {
    try {
      // Reset steps in memory
      _steps = 0;
      _goalCompleted = false;
      
      // Reset steps in preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('current_steps', 0);
      
      // Update UI
      _stepsController.add(_steps);
      if (onStepsChanged != null) {
        onStepsChanged!(0);
      }
      
      // Reset steps in Firestore
      await _firestore.collection('users').doc(userId).update({
        'current_steps': 0,
        'calories': 0,
        'distance': 0,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error resetting steps for new user: $e');
    }
  }
  
  /// Save steps asynchronously without blocking UI updates
  Future<void> _saveStepsAsync(int steps) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Save to cache with user-specific keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${user.uid}_current_steps', steps);
      
      // Calculate calories and distance
      final userData = await _userService.getCurrentUserData();
      final userWeight = userData?['weight'] as double?;
      final calories = calculateCaloriesBurned(steps, userWeight);
      final distance = calculateDistance(steps);
      
      // Update user data using UserService
      await _userService.updateUserSteps(steps, calories.toDouble(), distance);
      _lastFirestoreUpdate = DateTime.now();
      
      debugPrint('Saved steps to Firestore: $steps');
    } catch (e) {
      debugPrint('Error saving steps: $e');
      rethrow;
    }
  }
  
  /// Calculate calories burned from steps based on user weight
  int calculateCaloriesBurned(int steps, double? userWeight) {
    // Default weight in kg if not provided (70kg is average adult)
    final weight = userWeight ?? 70.0;
    
    // Formula based on weight: heavier people burn more calories per step
    // Base calorie burn is ~0.04 kcal per step for a 70kg person
    // We adjust this proportionally based on weight
    final caloriesPerStep = 0.04 * (weight / 70.0);
    
    // Calculate total calories
    return (steps * caloriesPerStep).round();
  }
  
  /// Calculate distance based on steps (approximate)
  double calculateDistance(int steps) {
    // Average stride length is about 0.7 meters per step
    // This gives approx 700m per 1000 steps
    return steps * 0.0007;
  }

  /// Update steps in Firestore
  Future<void> _updateFirestoreSteps() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get user weight for more accurate calorie calculation
      double? userWeight;
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['weight'] != null) {
            userWeight = (userData['weight'] as num).toDouble();
          }
        }
      } catch (e) {
        // Fallback to default weight calculation if we can't get the user's weight
        debugPrint('Error getting user weight: $e');
      }
      
      // Calculate calories and distance
      final calories = calculateCaloriesBurned(_steps, userWeight);
      final distance = calculateDistance(_steps);
      
      // Update user document with privacy settings
      await _firestore.collection('users').doc(userId).update({
        'current_steps': _steps,
        'calories': calories,
        'distance': distance,
        'last_updated': FieldValue.serverTimestamp(),
        'private': true, // Mark data as private
        'user_id': userId, // Ensure user ID is set
      });

      // Also update the daily tracking document
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_tracking')
          .doc(dateStr)
          .set({
            'steps': _steps,
            'calories': calories,
            'distance': distance,
            'timestamp': FieldValue.serverTimestamp(),
            'private': true,
            'user_id': userId,
          }, SetOptions(merge: true));
          
      _lastFirestoreUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error updating steps in Firestore: $e');
    }
  }
  
  /// Set user's step goal
  Future<void> setStepGoal(int goal) async {
    try {
      // Update goal in memory
      _goal = goal;
      _goalCompleted = _steps >= _goal;
      
      // Update UI callbacks
      if (onGoalChanged != null) {
        onGoalChanged!(_goal);
      }
      
      if (onGoalCompleted != null && _goalCompleted) {
        onGoalCompleted!(true, steps: _steps, goal: _goal);
      }
      
      // Save to Firestore using UserService
      await _userService.setStepGoal(goal);
    } catch (e) {
      debugPrint('Error setting step goal: $e');
    }
  }
  
  /// Save step history for a previous day
  Future<void> _saveStepHistory(int steps, String? dateStr) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Calculate calories and distance
      final userData = await _userService.getCurrentUserData();
      final userWeight = userData?['weight'] as double?;
      final calories = calculateCaloriesBurned(steps, userWeight);
      final distance = calculateDistance(steps);
      
      // Save to daily steps collection
      final date = dateStr != null 
          ? DateFormat('yyyy-MM-dd').parse(dateStr)
          : DateTime.now().subtract(const Duration(days: 1));
      
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      // Reference to user's personal document
      final userRef = _firestore.collection('users').doc(user.uid);
      
      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Save to user's daily steps collection with privacy settings
        final dailyStepRef = userRef
            .collection('daily_steps')
            .doc(formattedDate);
            
        transaction.set(dailyStepRef, {
          'steps': steps,
          'calories': calories,
          'distance': distance,
          'date': formattedDate,
          'timestamp': Timestamp.fromDate(date),
          'user_id': user.uid,
          'private': true, // Mark data as private
        }, SetOptions(merge: true));
        
        // Update user's main document
        transaction.update(userRef, {
          'last_history_update': Timestamp.fromDate(date),
          'private': true, // Mark data as private
        });
      });
    } catch (e) {
      debugPrint('Error saving step history: $e');
    }
  }
  
  /// Reset current steps to zero
  Future<void> resetSteps() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Reset steps in memory
      _steps = 0;
      _goalCompleted = false;
      
      // Reset steps in preferences with user-specific key
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('${user.uid}_current_steps', 0);
      
      // Update UI
      _stepsController.add(_steps);
      if (onStepsChanged != null) {
        onStepsChanged!(0);
      }
      
      // Reset steps in Firestore using UserService
      await _userService.updateUserSteps(0, 0, 0);
    } catch (e) {
      debugPrint('Error resetting steps: $e');
    }
  }
  
  /// Get user's step history
  Future<List<Map<String, dynamic>>> getStepHistory({int limit = 7}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Only get history for the current user
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_steps')
          .where('user_id', isEqualTo: user.uid) // Ensure only user's data is retrieved
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['date'],
          'steps': data['steps'],
          'calories': data['calories'],
          'distance': data['distance'],
          'timestamp': data['timestamp'],
          'user_id': data['user_id'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting step history: $e');
      return [];
    }
  }
  
  /// Initialize the pedometer stream
  Future<void> _initializePedometerStream() async {
    try {
      // Cancel any existing subscriptions
      await _stepCountSubscription?.cancel();
      
      // Reset tracking variables
      _isFirstReading = true;
      _initialSteps = 0;
      _lastStepTime = null;
      _lastStepCount = 0;
      
      // Start listening for step count updates
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) {
          debugPrint('Pedometer error: $error');
          // Try to reinitialize after a delay if there's an error
          Future.delayed(const Duration(seconds: 5), () {
            if (_stepCountSubscription == null) {
              _initializePedometerStream();
            }
          });
        },
      );
    } catch (e) {
      debugPrint('Error initializing pedometer: $e');
      // Try to reinitialize after a delay
      Future.delayed(const Duration(seconds: 5), _initializePedometerStream);
    }
  }
  
  /// Handle step count updates with improved accuracy
  void _onStepCount(StepCount event) async {
    final now = DateTime.now();
    
    // Initialize step counting on first reading
    if (_isFirstReading) {
      _initialSteps = event.steps;
      _isFirstReading = false;
      _lastStepTime = now;
      _lastStepCount = event.steps;
      
      // Keep existing steps from Firebase/cache instead of using pedometer's initial value
      debugPrint('Initial pedometer reading: ${event.steps}, keeping existing steps: $_steps');
    } else {
      // Calculate time difference between readings
      final timeDiff = now.difference(_lastStepTime!).inMilliseconds;
      
      // Calculate step difference from last reading
      final stepDiff = event.steps - _lastStepCount;
      
      // Update last values
      _lastStepTime = now;
      _lastStepCount = event.steps;
      
      // Apply filters for more accurate step counting
      if (stepDiff > 0) {
        // Validate step count increment
        if (timeDiff > 0 && stepDiff / (timeDiff / 1000) <= 10.0) {
          // Add the new steps to existing count
          _steps += stepDiff;
          debugPrint('Added $stepDiff steps, new total: $_steps');
          
          // Save steps immediately to cache
          final user = _auth.currentUser;
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('${user.uid}_current_steps', _steps);
          }
          
          // Update UI immediately using stream
          _stepsController.add(_steps);
          if (onStepsChanged != null) {
            onStepsChanged!(_steps);
          }
          
          // Check if goal completed
          if (_goal > 0 && _steps >= _goal && !_goalCompleted) {
            _goalCompleted = true;
            if (onGoalCompleted != null) {
              onGoalCompleted!(true, steps: _steps, goal: _goal);
            }
          }
          
          // Save to Firestore
          _saveStepsAsync(_steps);
        } else {
          debugPrint('Filtered out anomalous step reading: $stepDiff steps in $timeDiff ms');
        }
      }
    }
  }
  
  /// Pause tracking (temporarily)
  void pause() {
    _stepCountSubscription?.pause();
  }
  
  /// Cleanup resources when app is terminated
  /// This should only be called when the app is fully closing
  void dispose() {
    _stepCountSubscription?.cancel();
    _updateTimer?.cancel();
    _syncTimer?.cancel();
    _stepsController.close();
    _isInitialized = false;
  }
} 