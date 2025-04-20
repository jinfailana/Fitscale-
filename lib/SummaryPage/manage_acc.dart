import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
  final WorkoutHistoryService _historyService = WorkoutHistoryService();
  int _selectedIndex = 3; // Set to 3 for the "Me" tab

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
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
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => const FlLine(
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
                            checkToShowDot: (spot, barData) {
                              final index = barData.spots.indexOf(spot);
                              return index == 0 ||
                                  index == barData.spots.length - 1 ||
                                  index % 3 == 0;
                            },
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
                                getDrawingHorizontalLine: (value) => const FlLine(
                                  color: Colors.white10,
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => const FlLine(
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
                                    checkToShowDot: (spot, barData) {
                                      final index = barData.spots.indexOf(spot);
                                      return index == 0 ||
                                          index == barData.spots.length - 1 ||
                                          index % 3 == 0;
                                    },
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
                                            style: const TextStyle(
                                              color: Color(0xFFDF4D0F),
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
                                  isNewPasswordVisible =
                                      !isNewPasswordVisible;
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
