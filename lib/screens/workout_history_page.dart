import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final LocationService _locationService = LocationService();
  List<Map<String, dynamic>> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> workouts = await _locationService.getWorkoutSummary();
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading workout history: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workout history: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
      // If it's a Firestore Timestamp
      dateTime = timestamp.toDate();
    } else {
      return 'Invalid date';
    }
    
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  String _formatDuration(dynamic startTime, dynamic endTime) {
    if (startTime == null || endTime == null) return 'N/A';
    
    DateTime start;
    DateTime end;
    
    if (startTime is DateTime) {
      start = startTime;
    } else {
      start = startTime.toDate();
    }
    
    if (endTime is DateTime) {
      end = endTime;
    } else {
      end = endTime.toDate();
    }
    
    final difference = end.difference(start);
    
    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return 'N/A';
    
    double distanceValue;
    if (distance is double) {
      distanceValue = distance;
    } else if (distance is int) {
      distanceValue = distance.toDouble();
    } else {
      return 'Invalid distance';
    }
    
    if (distanceValue >= 1000) {
      return '${(distanceValue / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distanceValue.toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutHistory,
          ),
        ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _workouts.isEmpty
                ? _buildEmptyState()
                : _buildWorkoutList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a workout to track your progress',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.blue[600],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      workout['workoutType'] ?? 'Unknown Workout',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Started: ${_formatDate(workout['startTime'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${_formatDuration(workout['startTime'], workout['endTime'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const Divider(color: Colors.white30, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWorkoutStat(
                      label: 'Distance',
                      value: _formatDistance(workout['totalDistance']),
                      icon: Icons.straighten,
                    ),
                    if (workout['workoutGoal'] != null)
                      _buildWorkoutStat(
                        label: 'Goal',
                        value: workout['workoutGoal'],
                        icon: Icons.flag,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // View details button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    label: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      // Navigate to workout detail page (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout details feature coming soon'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 