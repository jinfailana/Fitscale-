import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controller for location updates
  Position? _lastKnownPosition;
  Stream<Position>? _positionStream;
  bool _isTracking = false;
  
  // Getter for current tracking status
  bool get isTracking => _isTracking;
  
  // Getter for last known position
  Position? get lastKnownPosition => _lastKnownPosition;
  
  /// Request location permission and check if service is enabled
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }
    
    // Permissions are granted
    return true;
  }
  
  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    
    if (!hasPermission) {
      return null;
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
  
  /// Start tracking user location and store in Firestore
  Future<bool> startLocationTracking({required String workoutId}) async {
    final hasPermission = await checkLocationPermission();
    final String? userId = _auth.currentUser?.uid;
    
    if (!hasPermission || userId == null) {
      return false;
    }
    
    _isTracking = true;
    
    try {
      // Use a more battery-friendly accuracy for continuous tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );
      
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);
      
      _positionStream!.listen((Position position) async {
        _lastKnownPosition = position;
        
        // Store the location data in Firestore
        await storeLocationData(position, workoutId);
      });
      
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
      return false;
    }
  }
  
  /// Stop tracking user location
  void stopLocationTracking() {
    _isTracking = false;
    _positionStream = null;
  }
  
  /// Store location data to Firestore
  Future<void> storeLocationData(Position position, String workoutId) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Calculate distance if there's previous data
      double? distanceTraveled;
      DocumentSnapshot? lastLocationDoc = await _getLastLocationEntry(userId, workoutId);
      
      if (lastLocationDoc.exists && lastLocationDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> lastData = lastLocationDoc.data() as Map<String, dynamic>;
        
        if (lastData.containsKey('latitude') && lastData.containsKey('longitude')) {
          double lastLat = lastData['latitude'];
          double lastLng = lastData['longitude'];
          
          // Calculate distance between last point and current point in meters
          distanceTraveled = Geolocator.distanceBetween(
            lastLat, lastLng, position.latitude, position.longitude
          );
        }
      }
      
      // Format the timestamp for readability
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      // Create the location data
      Map<String, dynamic> locationData = {
        'userId': userId,
        'workoutId': workoutId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedTimestamp': formattedDate,
      };
      
      // Add distance data if available
      if (distanceTraveled != null) {
        locationData['distanceFromLastPoint'] = distanceTraveled;
      }
      
      // Store in Firestore
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('locationData')
        .add(locationData);
      
      // Update the workout document with the latest location
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .update({
          'lastLocation': {
            'latitude': position.latitude, 
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
    } catch (e) {
      debugPrint('Error storing location data: $e');
    }
  }
  
  /// Get the last location entry for a specific workout
  Future<DocumentSnapshot> _getLastLocationEntry(String userId, String workoutId) async {
    QuerySnapshot querySnapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('workouts')
      .doc(workoutId)
      .collection('locationData')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    } else {
      // Return an empty document
      return await _firestore.collection('empty').doc('empty').get();
    }
  }
  
  /// Create a new workout session and return its ID
  Future<String?> createWorkoutSession({
    required String workoutType,
    String? plannedRoute,
    String? workoutGoal,
  }) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    try {
      // Get current position
      Position? position = await getCurrentPosition();
      
      // Create workout document
      DocumentReference workoutRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc();
      
      Map<String, dynamic> workoutData = {
        'workoutId': workoutRef.id,
        'userId': userId,
        'workoutType': workoutType,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'isCompleted': false,
        'totalDistance': 0.0,
        'plannedRoute': plannedRoute,
        'workoutGoal': workoutGoal,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Add starting location if available
      if (position != null) {
        workoutData['startLocation'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        };
      }
      
      await workoutRef.set(workoutData);
      return workoutRef.id;
    } catch (e) {
      debugPrint('Error creating workout session: $e');
      return null;
    }
  }
  
  /// Complete a workout session
  Future<bool> completeWorkoutSession(String workoutId) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    
    try {
      // Get current position for end location
      Position? position = await getCurrentPosition();
      
      // Calculate total distance
      double totalDistance = await _calculateTotalDistance(userId, workoutId);
      
      // Update workout document
      Map<String, dynamic> updateData = {
        'endTime': FieldValue.serverTimestamp(),
        'isCompleted': true,
        'totalDistance': totalDistance,
      };
      
      // Add ending location if available
      if (position != null) {
        updateData['endLocation'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        };
      }
      
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .update(updateData);
      
      // Stop tracking
      stopLocationTracking();
      
      return true;
    } catch (e) {
      debugPrint('Error completing workout session: $e');
      return false;
    }
  }
  
  /// Calculate total distance for a workout
  Future<double> _calculateTotalDistance(String userId, String workoutId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('locationData')
        .orderBy('timestamp')
        .get();
      
      double totalDistance = 0.0;
      List<DocumentSnapshot> docs = querySnapshot.docs;
      
      for (int i = 1; i < docs.length; i++) {
        Map<String, dynamic> currentData = docs[i].data() as Map<String, dynamic>;
        Map<String, dynamic> previousData = docs[i-1].data() as Map<String, dynamic>;
        
        if (currentData.containsKey('distanceFromLastPoint')) {
          totalDistance += currentData['distanceFromLastPoint'];
        } else if (currentData.containsKey('latitude') && 
                  currentData.containsKey('longitude') &&
                  previousData.containsKey('latitude') && 
                  previousData.containsKey('longitude')) {
          // Calculate distance between points
          double distance = Geolocator.distanceBetween(
            previousData['latitude'], 
            previousData['longitude'],
            currentData['latitude'], 
            currentData['longitude']
          );
          totalDistance += distance;
        }
      }
      
      return totalDistance;
    } catch (e) {
      debugPrint('Error calculating total distance: $e');
      return 0.0;
    }
  }
  
  /// Get a summary of all completed workouts
  Future<List<Map<String, dynamic>>> getWorkoutSummary() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    
    try {
      QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .where('isCompleted', isEqualTo: true)
        .orderBy('endTime', descending: true)
        .get();
      
      List<Map<String, dynamic>> workouts = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        workouts.add({
          'id': doc.id,
          ...data,
        });
      }
      
      return workouts;
    } catch (e) {
      debugPrint('Error getting workout summary: $e');
      return [];
    }
  }
} 