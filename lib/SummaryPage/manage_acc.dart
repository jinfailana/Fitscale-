import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ManageAccPage extends StatefulWidget {
  const ManageAccPage({super.key});

  @override
  State<ManageAccPage> createState() => _ManageAccPageState();
}

class _ManageAccPageState extends State<ManageAccPage> {
  String username = '';
  String signInMethod = '';
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
    return Container(
      height: 400, // Increased height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          _fetchWorkoutHistory().then((history) => {'history': history}),
          _fetchUserGoals().then((goals) => {'goals': goals}),
        ]).then((results) => {...results[0], ...results[1]}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDF4D0F)),
            );
          }

          if (!snapshot.hasData ||
              (snapshot.data!['history'] as List<WorkoutHistory>).isEmpty) {
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

          final workouts = snapshot.data!['history'] as List<WorkoutHistory>;

          // Filter to only include recommended workouts (from "My Workouts")
          final recommendedWorkouts = workouts
              .where((w) => w.workoutName.startsWith('My Workout'))
              .toList();

          if (recommendedWorkouts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Color(0xFFDF4D0F),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No recommended workout data to display',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add and complete recommended workouts to see progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group workouts by date
          final Map<DateTime, List<WorkoutHistory>> workoutsByDate = {};
          for (var workout in recommendedWorkouts) {
            final date = DateTime(
              workout.date.year,
              workout.date.month,
              workout.date.day,
            );
            workoutsByDate[date] = [...(workoutsByDate[date] ?? []), workout];
          }

          // Create spots for the line graph
          final spots = workoutsByDate.entries.map((entry) {
            final dailyWorkouts = entry.value;
            final completedWorkouts =
                dailyWorkouts.where((w) => w.isCompleted).length;
            final totalSets =
                dailyWorkouts.fold<int>(0, (sum, w) => sum + w.setsCompleted);

            // Calculate progress based on completion and sets
            final progress = (completedWorkouts / dailyWorkouts.length) * 100;

            return FlSpot(
              entry.key.millisecondsSinceEpoch.toDouble(),
              progress.clamp(0, 100),
            );
          }).toList()
            ..sort((a, b) => a.x.compareTo(b.x));

          // Calculate statistics for recommended workouts only
          final totalWorkouts = recommendedWorkouts.length;
          final completedWorkouts =
              recommendedWorkouts.where((w) => w.isCompleted).length;
          final totalSets = recommendedWorkouts.fold<int>(
              0, (sum, w) => sum + w.setsCompleted);
          final averageSetsPerWorkout =
              totalWorkouts > 0 ? (totalSets / totalWorkouts).round() : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Recommended Workout Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Progress chart
              SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
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
                            interval: (spots.last.x - spots.first.x) /
                                3, // Reduced number of date labels
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 25,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white54,
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
                        border: Border.all(color: Colors.white24),
                      ),
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFFDF4D0F),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFFDF4D0F),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFDF4D0F).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Recommended\nWorkouts',
                        totalWorkouts.toString(),
                        Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        '$completedWorkouts/$totalWorkouts',
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg. Sets',
                        averageSetsPerWorkout.toString(),
                        Icons.repeat,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in");
        return [];
      }

      print("Fetching workout history for user: ${user.uid}");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .orderBy('date', descending: true)
          .limit(50) // Increased limit to ensure we get enough data
          .get();

      print("Fetched ${querySnapshot.docs.length} workout history documents");

      final workouts = querySnapshot.docs
          .map((doc) {
            try {
              return WorkoutHistory.fromMap(doc.data());
            } catch (e) {
              print("Error parsing workout history: $e");
              return null;
            }
          })
          .where((workout) => workout != null)
          .cast<WorkoutHistory>()
          .toList();

      print("Successfully parsed ${workouts.length} workout history items");

      // Print some sample data for debugging
      if (workouts.isNotEmpty) {
        print(
            "Sample workout: ${workouts[0].workoutName}, completed: ${workouts[0].isCompleted}, sets: ${workouts[0].setsCompleted}/${workouts[0].totalSets}");
      }

      return workouts;
    } catch (e) {
      print('Error fetching workout history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDF4D0F)),
          onPressed: () => Navigator.pop(context),
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
                    SizedBox(
                      height: 220,
                      child: FutureBuilder<List<WorkoutHistory>>(
                        future: _fetchWorkoutHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFDF4D0F),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.white24, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'No workout data available',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Text(
                                    'Complete workouts to see your progress',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          final workouts = snapshot.data!;
                          print("Fetched ${workouts.length} workouts");

                          if (workouts.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.white24, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'No workout data available',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Text(
                                    'Complete workouts to see your progress',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          final spots = _createDataPoints(workouts);
                          print(
                              "Generated ${spots.length} spots for the graph");

                          if (spots.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.white24, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'No workout progress to display',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Text(
                                    'Complete more workouts to track progress',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white10,
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.white10,
                                  strokeWidth: 1,
                                ),
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
                                    reservedSize: 25,
                                    interval:
                                        (spots.last.x - spots.first.x) / 4,
                                    getTitlesWidget: (value, meta) {
                                      final date =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              value.toInt());
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
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
                                    reservedSize: 30,
                                    interval: 25,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text(
                                          '${value.toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: spots.first.x,
                              maxX: spots.last.x,
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: const Color(0xFFDF4D0F),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                      radius: 4,
                                      color: const Color(0xFFDF4D0F),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFFDF4D0F)
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ],
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: 70,
                                    color: Colors.green.withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      padding: const EdgeInsets.only(
                                          right: 5, bottom: 5),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                      ),
                                      labelResolver: (line) => 'Goal',
                                    ),
                                  ),
                                ],
                              ),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor:
                                      const Color(0xFF2A2A2A).withOpacity(0.8),
                                  tooltipRoundedRadius: 8,
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots
                                        .map((LineBarSpot touchedSpot) {
                                      final date =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              touchedSpot.x.toInt());
                                      return LineTooltipItem(
                                        '${DateFormat('MM/dd').format(date)}\n',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${touchedSpot.y.toInt()}% progress',
                                            style: TextStyle(
                                              color: const Color(0xFFDF4D0F),
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress Stats
                    FutureBuilder<List<WorkoutHistory>>(
                      future: _fetchWorkoutHistory(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final workouts = snapshot.data!;
                        final recommendedWorkouts = workouts
                            .where(
                                (w) => w.workoutName.startsWith('My Workout'))
                            .toList();

                        if (recommendedWorkouts.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final totalWorkouts = recommendedWorkouts.length;
                        final completedWorkouts = recommendedWorkouts
                            .where((w) => w.isCompleted)
                            .length;
                        final totalSets = recommendedWorkouts.fold<int>(
                            0, (sum, w) => sum + w.setsCompleted);
                        final totalPossibleSets = recommendedWorkouts.fold<int>(
                            0, (sum, w) => sum + w.totalSets);

                        // Calculate overall progress
                        final completionRate = totalWorkouts > 0
                            ? (completedWorkouts / totalWorkouts) * 100
                            : 0.0;
                        final setsRate = totalPossibleSets > 0
                            ? (totalSets / totalPossibleSets) * 100
                            : 0.0;
                        final overallProgress =
                            ((completionRate + setsRate) / 2).round();

                        // Calculate streak
                        int currentStreak = 0;
                        if (recommendedWorkouts.isNotEmpty) {
                          final groupedByDate =
                              <DateTime, List<WorkoutHistory>>{};
                          for (var workout in recommendedWorkouts) {
                            final date = DateTime(
                              workout.date.year,
                              workout.date.month,
                              workout.date.day,
                            );
                            if (!groupedByDate.containsKey(date)) {
                              groupedByDate[date] = [];
                            }
                            groupedByDate[date]!.add(workout);
                          }

                          final sortedDates = groupedByDate.keys.toList()
                            ..sort((a, b) => b.compareTo(a)); // Sort descending

                          final today = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          );

                          // Check if there's a workout today
                          bool hasWorkoutToday = sortedDates.isNotEmpty &&
                              sortedDates[0].isAtSameMomentAs(today);

                          if (hasWorkoutToday ||
                              sortedDates.isNotEmpty &&
                                  today.difference(sortedDates[0]).inDays ==
                                      1) {
                            // Start counting streak
                            currentStreak = hasWorkoutToday ? 1 : 0;

                            for (int i = hasWorkoutToday ? 1 : 0;
                                i < sortedDates.length;
                                i++) {
                              final currentDate = sortedDates[i];
                              final previousDate = sortedDates[i - 1];

                              // If dates are consecutive, increase streak
                              if (previousDate.difference(currentDate).inDays ==
                                  1) {
                                currentStreak++;
                              } else {
                                break;
                              }
                            }
                          }
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProgressStat('Progress', '$overallProgress%',
                                Icons.trending_up),
                            _buildProgressStat(
                                'Completed',
                                '$completedWorkouts/$totalWorkouts',
                                Icons.check_circle),
                            _buildProgressStat(
                                'Streak',
                                currentStreak.toString(),
                                Icons.local_fire_department),
                          ],
                        );
                      },
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'New Username',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty && newUsername != username) {
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
                          content: Text('Username changed successfully.'),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error changing username: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change username: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmNewPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmNewPassword =
                    confirmNewPasswordController.text.trim();

                if (newPassword != confirmNewPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match.'),
                    ),
                  );
                  return;
                }

                if (newPassword.isNotEmpty && currentPassword.isNotEmpty) {
                  try {
                    // Re-authenticate the user
                    final user = FirebaseAuth.instance.currentUser;
                    final cred = EmailAuthProvider.credential(
                        email: user!.email!, password: currentPassword);

                    await user.reauthenticateWithCredential(cred);

                    // Update the password
                    await user.updatePassword(newPassword);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully.'),
                      ),
                    );
                  } catch (e) {
                    print('Error changing password: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change password: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
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
                  Navigator.pushReplacementNamed(context, '/login');
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

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFDF4D0F), size: 24),
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
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  List<FlSpot> _createDataPoints(List<WorkoutHistory> workouts) {
    // Print for debugging
    print("Total workouts fetched: ${workouts.length}");

    // Filter to include all workouts, not just "My Workout"
    // This ensures we're not missing any data
    final filteredWorkouts = workouts.toList();

    print("Filtered workouts: ${filteredWorkouts.length}");

    if (filteredWorkouts.isEmpty) {
      return [];
    }

    // Sort workouts by date (oldest to newest)
    filteredWorkouts.sort((a, b) => a.date.compareTo(b.date));

    // Get date range (last 30 days)
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(const Duration(days: 29));

    print("Date range: $startDate to $endDate");

    // Create a map of dates to track cumulative progress
    final Map<DateTime, double> progressByDate = {};
    double cumulativeProgress = 0;

    // Initialize with start date
    DateTime currentDate =
        DateTime(startDate.year, startDate.month, startDate.day);

    // Group workouts by date
    final Map<DateTime, List<WorkoutHistory>> workoutsByDate = {};
    for (var workout in filteredWorkouts) {
      final date = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );

      if (!workoutsByDate.containsKey(date)) {
        workoutsByDate[date] = [];
      }
      workoutsByDate[date]!.add(workout);
    }

    print("Dates with workouts: ${workoutsByDate.keys.length}");

    // Calculate cumulative progress over time
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      // If there are workouts for this date, calculate progress
      if (workoutsByDate.containsKey(currentDate)) {
        final dailyWorkouts = workoutsByDate[currentDate]!;
        final completedWorkouts =
            dailyWorkouts.where((w) => w.isCompleted).length;

        // Ensure we don't divide by zero
        final totalSets =
            dailyWorkouts.fold<int>(0, (sum, w) => sum + w.setsCompleted);
        final totalPossibleSets = dailyWorkouts.fold<int>(
            0,
            (sum, w) =>
                sum +
                (w.totalSets > 0
                    ? w.totalSets
                    : 3)); // Default to 3 sets if totalSets is 0

        // Calculate daily progress (50% completion rate, 50% sets completed)
        final completionRate = dailyWorkouts.isNotEmpty
            ? (completedWorkouts / dailyWorkouts.length)
            : 0.0;
        final setsRate =
            totalPossibleSets > 0 ? (totalSets / totalPossibleSets) : 0.0;

        // Add daily progress to cumulative total (max 100)
        // Increase the increment to make progress more visible
        final dailyIncrement = (completionRate * 0.5 + setsRate * 0.5) * 15;
        cumulativeProgress += dailyIncrement;

        print(
            "Date: $currentDate, Workouts: ${dailyWorkouts.length}, Completed: $completedWorkouts, Progress: $dailyIncrement, Cumulative: $cumulativeProgress");
      } else {
        // Small increment even on days without workouts to show some progress
        cumulativeProgress += 0.5;
      }

      // Ensure progress stays within bounds
      cumulativeProgress = cumulativeProgress.clamp(0, 100);

      // Store cumulative progress for this date
      progressByDate[currentDate] = cumulativeProgress;

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Convert to FlSpots for the chart
    final spots = progressByDate.entries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value,
      );
    }).toList();

    print("Generated ${spots.length} data points for the graph");

    // Ensure we have at least two points for the graph
    if (spots.length < 2) {
      // Create default data if we don't have enough real data
      return [
        FlSpot(startDate.millisecondsSinceEpoch.toDouble(), 0),
        FlSpot(endDate.millisecondsSinceEpoch.toDouble(), 0),
      ];
    }

    return spots;
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
