import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_plan.dart';
import '../models/workout_history.dart';
import 'manage_acc.dart';
import 'steps_page.dart';
import 'measure_weight.dart';
import '../HistoryPage/history.dart';
import '../screens/recommendations_page.dart';
import '../models/user_model.dart';
import '../services/workout_history_service.dart';
import 'package:intl/intl.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  int _selectedIndex = 0;
  String username = '';
  String email = '';
  double userWeight = 0.0;
  List<WorkoutHistory> _recentWorkouts = [];
  bool _isLoading = true;
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadRecentWorkouts();
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
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            username = userData['username'] ?? '';
            email = userData['email'] ?? '';
            userWeight = (userData['weight'] ?? 0.0).toDouble();
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _loadRecentWorkouts() async {
    try {
      final history = await _historyService.getWorkoutHistory();
      setState(() {
        // Get unique workouts by name and date, sorted by date
        final uniqueWorkouts = history
            .fold<Map<String, WorkoutHistory>>(
              {},
              (map, workout) {
                final key =
                    '${workout.workoutName}_${workout.date.toIso8601String()}';
                if (!map.containsKey(key)) {
                  map[key] = workout;
                }
                return map;
              },
            )
            .values
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Take only the 3 most recent workouts
        _recentWorkouts = uniqueWorkouts.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent workouts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      Navigator.push(
        context,
        CustomPageRoute(child: const HistoryPage()),
      );
    } else if (index == 3) {
      _showProfileModal(context);
    } else if (index == 1) {
      _loadAndNavigateToRecommendations();
    }
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
      print('Fetched user data: $userData'); // Debug print

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

      print('Created UserModel: ${userModel.toMap()}'); // Debug print

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

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(_selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon,
            color: _selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.white54),
      ),
      label: label,
    );
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 30, 1.0),
            borderRadius: const BorderRadius.only(
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
                    Padding(
                      padding: const EdgeInsets.only(right: 75.0),
                      child: const Text(
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
                        setState(() {
                          _selectedIndex = 0;
                        });
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
                _buildProfileOption(Icons.person, username, email),
                const SizedBox(height: 10),
                _buildProfileOption(Icons.devices, 'My Device', ''),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        if (title == username) {
          Navigator.push(
            context,
            CustomPageRoute(child: const ManageAccPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromRGBO(223, 77, 15, 1.0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Color.fromRGBO(223, 77, 15, 1.0)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/Fitscale_LOGO.png',
          height: 80,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              'Welcome, $username',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.person, color: Color.fromRGBO(223, 77, 15, 1.0)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0.1),
              const Text(
                'Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildAnimatedSummaryCard('Set Step Goal',
                  'Daily goal: No goal yet', Icons.directions_walk),
              _buildAnimatedSummaryCard(
                  userWeight > 0 ? '${userWeight.toStringAsFixed(1)}kg' : '0kg',
                  'Current Weight',
                  Icons.monitor_weight),
              _buildAnimatedSummaryCard(
                  'Set Diets!', 'Mark your meals today!', Icons.restaurant),
              const SizedBox(height: 20),
              const Text(
                'Recent Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color.fromRGBO(223, 77, 15, 1.0),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recentWorkouts.isEmpty
                        ? const Center(
                            child: Text(
                              'No Workouts Found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recentWorkouts.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final workout = _recentWorkouts[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            223, 77, 15, 0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: Color.fromRGBO(
                                            223, 77, 15, 1.0),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workout.workoutName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${workout.setsCompleted}/${workout.totalSets} sets completed',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM d, y')
                                                .format(workout.date),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 20), // Add some padding at the bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          selectedItemColor: const Color.fromRGBO(223, 77, 15, 1.0),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.fitness_center, 'Workouts', 1),
            _buildNavItem(Icons.history, 'History', 2),
            _buildNavItem(Icons.person, 'Me', 3),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildAnimatedSummaryCard(
      String title, String subtitle, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Handle navigation based on the card type
        if (title == 'Set Step Goal') {
          Navigator.push(
            context,
            CustomPageRoute(child: const StepsPage()),
          );
        } else if (title.contains('kg')) {
          // Navigate to MeasureWeightPage when weight card is tapped
          Navigator.push(
            context,
            CustomPageRoute(child: const MeasureWeightPage()),
          ).then((_) {
            // Refresh data when returning from MeasureWeightPage
            _fetchUserData();
          });
        }
        // Add more conditions for other cards if needed
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Color.fromRGBO(223, 77, 15, 1.0)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
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
                    color: Color.fromRGBO(223, 77, 15, 1.0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Icon(icon, color: Color.fromRGBO(223, 77, 15, 1.0), size: 40),
          ],
        ),
      ),
    );
  }
}

class AnimatedContainerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedContainerWidget(
      {super.key, required this.child, required this.onTap});

  @override
  AnimatedContainerWidgetState createState() => AnimatedContainerWidgetState();
}

class AnimatedContainerWidgetState extends State<AnimatedContainerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: widget.child,
      ),
    );
  }
}