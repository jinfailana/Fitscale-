import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class WorkoutTrackerPage extends StatefulWidget {
  final String workoutType;
  final String? workoutGoal;
  
  const WorkoutTrackerPage({
    Key? key, 
    required this.workoutType,
    this.workoutGoal,
  }) : super(key: key);

  @override
  State<WorkoutTrackerPage> createState() => _WorkoutTrackerPageState();
}

class _WorkoutTrackerPageState extends State<WorkoutTrackerPage> {
  final LocationService _locationService = LocationService();
  
  String? _workoutId;
  bool _isTracking = false;
  Position? _currentPosition;
  String _elapsedTime = '00:00:00';
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  
  DateTime? _startTime;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.activityRecognition,
    ].request();
    
    // Check if permissions were granted
    if (statuses[Permission.location] == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      _showPermissionDeniedDialog();
    }
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is needed to track your workout. Please enable it in app settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _currentSpeed = position.speed;
        });
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }
  
  Future<void> _startWorkout() async {
    try {
      // Create a new workout session
      _workoutId = await _locationService.createWorkoutSession(
        workoutType: widget.workoutType,
        workoutGoal: widget.workoutGoal,
      );
      
      if (_workoutId != null) {
        // Start location tracking
        bool trackingStarted = await _locationService.startLocationTracking(
          workoutId: _workoutId!,
        );
        
        if (trackingStarted) {
          setState(() {
            _isTracking = true;
            _startTime = DateTime.now();
            _totalDistance = 0.0;
          });
          
          // Start timer for elapsed time
          _startTimer();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout tracking started')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start location tracking')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create workout session')),
        );
      }
    } catch (e) {
      debugPrint('Error starting workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _stopWorkout() async {
    if (_workoutId != null) {
      try {
        bool completed = await _locationService.completeWorkoutSession(_workoutId!);
        
        if (completed) {
          setState(() {
            _isTracking = false;
          });
          
          _timer?.cancel();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout completed and saved')),
          );
          
          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop(true); // Return true to indicate completion
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to complete workout')),
          );
        }
      } catch (e) {
        debugPrint('Error stopping workout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_startTime!);
        
        // Format the duration as HH:MM:SS
        final hours = difference.inHours.toString().padLeft(2, '0');
        final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
        
        setState(() {
          _elapsedTime = '$hours:$minutes:$seconds';
          
          // Update current position and speed if available
          if (_locationService.lastKnownPosition != null) {
            _currentPosition = _locationService.lastKnownPosition;
            _currentSpeed = _currentPosition?.speed ?? 0.0;
          }
        });
      }
    });
  }
  
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
  }
  
  String _formatSpeed(double speedInMetersPerSecond) {
    // Convert m/s to km/h
    double speedInKmh = speedInMetersPerSecond * 3.6;
    return '${speedInKmh.toStringAsFixed(1)} km/h';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workoutType} Tracker'),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Workout info card
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.blue[700],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        widget.workoutType,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.workoutGoal != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Goal: ${widget.workoutGoal}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      const Divider(color: Colors.white30, height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(
                            icon: Icons.timer,
                            label: 'Time',
                            value: _elapsedTime,
                          ),
                          _buildInfoItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: _formatDistance(_totalDistance),
                          ),
                          _buildInfoItem(
                            icon: Icons.speed,
                            label: 'Speed',
                            value: _formatSpeed(_currentSpeed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Location info
              if (_currentPosition != null)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.blue[600],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLocationInfo(
                              label: 'Latitude',
                              value: _currentPosition!.latitude.toStringAsFixed(6),
                            ),
                            _buildLocationInfo(
                              label: 'Longitude',
                              value: _currentPosition!.longitude.toStringAsFixed(6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLocationInfo(
                              label: 'Altitude',
                              value: '${_currentPosition!.altitude.toStringAsFixed(1)} m',
                            ),
                            _buildLocationInfo(
                              label: 'Accuracy',
                              value: '${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Start/Stop button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isTracking ? _stopWorkout : _startWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _isTracking ? 'STOP WORKOUT' : 'START WORKOUT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocationInfo({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 