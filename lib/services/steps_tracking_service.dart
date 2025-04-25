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
  
  // Add Firebase listener
  StreamSubscription<DocumentSnapshot>? _firebaseListener;
  
  // Add current user ID tracking
  String? _currentUserId;
  
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
  Function(bool, {int? steps, int? goal})? onGoalCompleted;
  
  /// Reset service for new user
  Future<void> resetForNewUser() async {
    try {
      debugPrint('Starting complete reset for new user');
      
      // First save any pending steps for previous user
      if (_currentUserId != null) {
        await _updateFirestoreSteps();
        
        // Clear cache for previous user
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${_currentUserId}_current_steps');
        await prefs.remove('${_currentUserId}_last_step_date');
        debugPrint('Cleared cache for previous user: $_currentUserId');
      }

      // Cancel all existing subscriptions and timers
      _stepCountSubscription?.cancel();
      _stepCountSubscription = null;
      _updateTimer?.cancel();
      _updateTimer = null;
      _syncTimer?.cancel();
      _syncTimer = null;
      _firebaseListener?.cancel();
      _firebaseListener = null;

      // Reset tracking variables but keep steps count until we load new data
      _initialSteps = 0;
      _isFirstReading = true;
      _goal = 0;
      _goalCompleted = false;
      _lastStepTime = null;
      _lastStepCount = 0;
      _lastFirestoreUpdate = null;
      _isInitialized = false;
      
      // Get current user
      final user = _auth.currentUser;
      if (user != null && user.uid != _currentUserId) {
        debugPrint('Detected new user: ${user.uid}, old user: $_currentUserId');
        _currentUserId = user.uid;
        
        // Load existing data for the new user first
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['current_steps'] != null) {
            _steps = data['current_steps'] as int;
            debugPrint('Loaded existing steps for new user: $_steps');
          }
        }
        
        // Load fresh data for new user
        await _loadUserData();
        
        // Setup Firebase listener first to ensure we don't miss updates
        _setupFirebaseListener();
        
        // Then initialize tracking
        await _initializePedometerStream();
        
        // Setup new timers
        _setupTimers();
        
        _isInitialized = true;
        debugPrint('Reset completed for new user: ${user.uid} with steps: $_steps');
      }
    } catch (e) {
      debugPrint('Error resetting service for new user: $e');
    }
  }

  void _setupTimers() {
    // Cancel existing timers first
    _updateTimer?.cancel();
    _syncTimer?.cancel();

    // Update UI more frequently (every 1 second)
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _stepsController.add(_steps);
      if (onStepsChanged != null) {
        onStepsChanged!(_steps);
      }
    });
    
    // Sync with Firestore more frequently (every 15 seconds)
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateFirestoreSteps();
    });
  }

  /// Load user data, including current steps and goals
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      debugPrint('Loading data for user: ${user.uid}');
      
      // Get current date
      final today = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(today);
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('${user.uid}_last_step_date');
      
      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final stepsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(formattedDate)
          .get();

      // If it's a new day
      if (lastDate != formattedDate) {
        debugPrint('New day detected. Last date: $lastDate, Current date: $formattedDate');
        
        // Save yesterday's data if exists
        if (_steps > 0) {
          await _saveStepHistory(_steps, lastDate ?? DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1))));
        }
        
        // Don't reset steps if we already have steps for today
        if (!stepsDoc.exists) {
          _steps = 0;
          _initialSteps = 0;
          debugPrint('New day, no existing steps found. Resetting to 0.');
        } else {
          _steps = stepsDoc.data()?['steps'] ?? 0;
          debugPrint('New day, but found existing steps: $_steps');
        }
        
        await prefs.setString('${user.uid}_last_step_date', formattedDate);
      } else {
        // Load steps from Firestore first
        if (stepsDoc.exists) {
          final firestoreSteps = stepsDoc.data()?['steps'] ?? 0;
          debugPrint('Loaded steps from Firestore: $firestoreSteps');
          
          // Get cached steps
          final cachedSteps = prefs.getInt('${user.uid}_current_steps') ?? 0;
          debugPrint('Loaded steps from cache: $cachedSteps');
          
          // Use the larger value between Firestore and cache
          _steps = firestoreSteps > cachedSteps ? firestoreSteps : cachedSteps;
          debugPrint('Using larger value for steps: $_steps');
        }
      }

      // Save current steps to cache
      await prefs.setInt('${user.uid}_current_steps', _steps);
      
      // Update UI immediately
      _stepsController.add(_steps);
      if (onStepsChanged != null) {
        onStepsChanged!(_steps);
      }

      // Get user's step goal
      if (userDoc.exists) {
        _goal = userDoc.data()?['step_goal'] ?? 0;
        debugPrint('Loaded step goal: $_goal');
      }

      debugPrint('Successfully loaded user data. Steps: $_steps, Goal: $_goal');
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

  /// Resume tracking after login or app resume
  Future<void> resume() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in during resume');
        return;
      }

      // Check if user has changed
      if (user.uid != _currentUserId) {
        debugPrint('Different user detected during resume, resetting service');
        await resetForNewUser();
        return;
      }

      debugPrint('Resuming step tracking for user: ${user.uid}');

      // Load latest data from Firestore first
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['current_steps'] != null) {
          _steps = data['current_steps'] as int;
          debugPrint('Loaded steps from Firestore: $_steps');
          
          // Update cache with Firestore data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('${user.uid}_current_steps', _steps);
          
          // Update UI
          _stepsController.add(_steps);
          if (onStepsChanged != null) {
            onStepsChanged!(_steps);
          }
        }
      }

      // If not initialized, do full initialization
      if (!_isInitialized) {
        await initialize();
        return;
      }
      
      // Setup Firebase listener again
      _setupFirebaseListener();
      
      // If already initialized but pedometer subscription was canceled, reconnect it
      if (_stepCountSubscription == null) {
        await _initializePedometerStream();
      }
      
      // Restart timers if they were stopped
      _setupTimers();

      debugPrint('Successfully resumed step tracking. Current steps: $_steps');
    } catch (e) {
      debugPrint('Error in resume: $e');
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
  
  /// Update steps in Firestore
  Future<void> _updateFirestoreSteps() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != _currentUserId) return;

      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      // Calculate calories and distance
      final userData = await _userService.getCurrentUserData();
      final userWeight = userData?['weight'] as double?;
      final calories = calculateCaloriesBurned(_steps, userWeight);
      final distance = calculateDistance(_steps);

      // Create consistent data object for both collections
      final stepsData = {
        'steps': _steps,
        'calories': calories,
        'distance': distance,
        'date': Timestamp.fromDate(DateTime.parse(dateStr)),
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      };

      // Update both collections with the same data
      await Future.wait([
        // Update steps collection with daily data
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .doc(dateStr)
            .set(stepsData, SetOptions(merge: true)),

        // Update main user document with current data
        _firestore.collection('users').doc(user.uid).update({
          'current_steps': _steps,
          'current_calories': calories,
          'current_distance': distance,
          'last_updated': FieldValue.serverTimestamp(),
        })
      ]);

      _lastFirestoreUpdate = now;
      debugPrint('Successfully updated steps data in Firestore: steps=$_steps, calories=$calories, distance=$distance');
    } catch (e) {
      debugPrint('Error updating steps in Firestore: $e');
    }
  }
  
  /// Calculate calories burned from steps based on user weight
  int calculateCaloriesBurned(int steps, double? userWeight) {
    // Default weight in kg if not provided (70kg is average adult)
    final weight = userWeight ?? 70.0;
    
    // Formula based on weight and steps:
    // - Average person burns 0.04 calories per step at 70kg
    // - Adjust based on actual weight
    // - Add intensity factor based on step rate
    final caloriesPerStep = 0.04 * (weight / 70.0);
    
    // Calculate total calories
    final totalCalories = steps * caloriesPerStep;
    
    return totalCalories.round();
  }
  
  /// Calculate distance based on steps (approximate)
  double calculateDistance(int steps) {
    // Average stride length is about 0.762 meters (2.5 feet) per step
    // This is a more accurate measurement than previous 0.7m
    const strideLength = 0.762;  // meters per step
    
    // Convert to kilometers
    return (steps * strideLength) / 1000;
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
      
      // Create consistent data object
      final historyData = {
        'steps': steps,
        'calories': calories,
        'distance': distance,
        'date': Timestamp.fromDate(date),
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      };
      
      // Save to steps collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(formattedDate)
          .set(historyData, SetOptions(merge: true));
          
      debugPrint('Successfully saved step history: steps=$steps, calories=$calories, distance=$distance');
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
  
  /// Get user's step history with consistent calculations
  Future<List<Map<String, dynamic>>> getStepHistory({int limit = 7}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get user weight for accurate calorie calculations
      final userData = await _userService.getCurrentUserData();
      final userWeight = userData?['weight'] as double?;

      // Get history data
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final steps = data['steps'] as int? ?? 0;
        
        // Recalculate calories and distance to ensure consistency
        final calories = calculateCaloriesBurned(steps, userWeight);
        final distance = calculateDistance(steps);
        
        return {
          'date': data['date'],
          'steps': steps,
          'calories': calories,
          'distance': distance,
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
      // Cancel any existing subscription
      await _stepCountSubscription?.cancel();
      _stepCountSubscription = null;
      
      // Reset tracking variables
      _isFirstReading = true;
      _initialSteps = 0;
      _lastStepTime = null;
      _lastStepCount = 0;
      
      debugPrint('Initializing pedometer for user: $_currentUserId');
      
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
  
  /// Handle step count updates with improved accuracy and persistence
  void _onStepCount(StepCount event) async {
    try {
      final now = DateTime.now();
      
      // Initialize step counting on first reading
      if (_isFirstReading) {
        // Load existing steps from cache first
        final user = _auth.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          _steps = prefs.getInt('${user.uid}_current_steps') ?? _steps;
        }
        
        _initialSteps = event.steps;
        _isFirstReading = false;
        _lastStepTime = now;
        _lastStepCount = event.steps;
        
        // Update UI with current steps
        _stepsController.add(_steps);
        if (onStepsChanged != null) {
          onStepsChanged!(_steps);
        }
        
        debugPrint('Initial steps from cache: $_steps, Pedometer reading: ${event.steps}');
        return;
      }
      
      // Calculate time difference between readings
      final timeDiff = now.difference(_lastStepTime!).inMilliseconds;
      
      // Calculate step difference from last reading
      final stepDiff = event.steps - _lastStepCount;
      
      // Update last values
      _lastStepTime = now;
      _lastStepCount = event.steps;
      
      // Apply filters for more accurate step counting
      if (stepDiff > 0 && stepDiff < 50) { // Maximum step difference filter
        // Validate step count increment
        if (timeDiff > 0 && stepDiff / (timeDiff / 1000) <= 10.0) {
          // Add the new steps to existing count
          _steps += stepDiff;
          debugPrint('Added $stepDiff steps, new total: $_steps');
          
          // Save steps immediately to cache and Firestore
          final user = _auth.currentUser;
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('${user.uid}_current_steps', _steps);
            
            // Update Firestore immediately for real-time sync
            await _updateFirestoreSteps();
            
            debugPrint('Saved steps to cache and Firestore: $_steps');
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
        } else {
          debugPrint('Filtered out anomalous step reading: $stepDiff steps in $timeDiff ms');
        }
      }
    } catch (e) {
      debugPrint('Error in _onStepCount: $e');
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
    _firebaseListener?.cancel();
    _stepsController.close();
    _isInitialized = false;
  }

  /// Initialize the step tracking service
  Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in during initialization');
        return;
      }

      // Clear any existing data first to prevent data mixing
      _steps = 0;
      _initialSteps = 0;
      _lastStepCount = 0;
      
      // Cancel existing subscriptions
      _stepCountSubscription?.cancel();
      _updateTimer?.cancel();
      _syncTimer?.cancel();
      _firebaseListener?.cancel();

      debugPrint('Initializing step tracking service for user: ${user.uid}');
      
      // Set current user ID first to ensure proper data isolation
      _currentUserId = user.uid;

      // Setup Firebase listener first to get immediate updates
      _setupFirebaseListener();
      
      // Load user data in parallel with pedometer setup
      final dataFuture = _loadUserData();
      final pedometerFuture = _initializePedometerStream();
      
      // Wait for both to complete
      await Future.wait([dataFuture, pedometerFuture]);
      
      // Setup timers for updates with shorter intervals
      _setupTimers();
      
      _isInitialized = true;
      debugPrint('Step tracking service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing step tracking service: $e');
      _isInitialized = false;
    }
  }

  /// Setup Firebase listener for real-time updates
  void _setupFirebaseListener() {
    try {
      // Cancel any existing subscription
      _firebaseListener?.cancel();
      
      final user = _auth.currentUser;
      if (user == null) return;
      
      debugPrint('Setting up Firebase listener for user: ${user.uid}');
      
      // Listen to user document for step and goal updates
      _firebaseListener = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists || !mounted) return;
        
        // Verify we're still on the same user
        if (user.uid != _currentUserId) {
          debugPrint('User mismatch, cancelling update');
          return;
        }
        
        final data = snapshot.data()!;
        final firebaseSteps = data['current_steps'] as int?;
        final firebaseGoal = data['step_goal'] as int?;
        final lastUpdateTime = data['last_updated'] as Timestamp?;
        
        // Get current cache
        final prefs = await SharedPreferences.getInstance();
        final cachedSteps = prefs.getInt('${user.uid}_current_steps') ?? 0;
        
        // If Firebase has newer data (based on timestamp) or higher step count
        if (lastUpdateTime != null && firebaseSteps != null) {
          final shouldUpdate = firebaseSteps > _steps || 
                             (lastUpdateTime.toDate().isAfter(_lastFirestoreUpdate ?? DateTime(2000)));
          
          if (shouldUpdate) {
            debugPrint('Updating steps from Firebase. Old: $_steps, New: $firebaseSteps');
            _steps = firebaseSteps;
            
            // Update local cache
            await prefs.setInt('${user.uid}_current_steps', _steps);
            
            // Update UI immediately
            _stepsController.add(_steps);
            if (onStepsChanged != null) {
              onStepsChanged!(_steps);
            }
            
            // Update last update time
            _lastFirestoreUpdate = lastUpdateTime.toDate();
          }
        }
        
        // Update goal if changed
        if (firebaseGoal != null && firebaseGoal != _goal) {
          debugPrint('Updating goal from Firebase. Old: $_goal, New: $firebaseGoal');
          _goal = firebaseGoal;
          if (onGoalChanged != null) {
            onGoalChanged!(_goal);
          }
        }
        
        // Check goal completion
        final newGoalCompleted = _goal > 0 && _steps >= _goal;
        if (newGoalCompleted && !_goalCompleted) {
          _goalCompleted = true;
          if (onGoalCompleted != null) {
            onGoalCompleted!(true, steps: _steps, goal: _goal);
          }
        }
      }, onError: (e) {
        debugPrint('Error in Firebase listener: $e');
      });
    } catch (e) {
      debugPrint('Error setting up Firebase listener: $e');
    }
  }

  /// Add this getter for the mounted property
  bool get mounted => true;
} 