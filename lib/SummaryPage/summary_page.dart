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
import '../screens/diet_recommendations_page.dart';
import '../screens/selected_diet_page.dart';
import '../models/user_model.dart';
import '../services/workout_history_service.dart';
import '../services/diet_service.dart';
import '../models/diet_plan.dart';
import 'package:intl/intl.dart';
import '../navigation/custom_navbar.dart';
import '../utils/custom_page_route.dart';

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
  late final WorkoutHistoryService _historyService;
  final DietService _dietService = DietService();
  String? _selectedDietPlanId;
  DietPlan? _selectedDietPlan;
  bool _loadingDiet = true;
  final GlobalKey<CustomNavBarState> _navbarKey =
      GlobalKey<CustomNavBarState>();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _historyService = WorkoutHistoryService(userId: user.uid);
    }
    _fetchUserData();
    _loadRecentWorkouts();
    _loadSelectedDiet();
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

  Future<void> _loadSelectedDiet() async {
    try {
      setState(() => _loadingDiet = true);

      // Get the selected diet plan ID
      final selectedDietPlanId = await _dietService.getSelectedDietPlan();
      _selectedDietPlanId = selectedDietPlanId;

      // If user has a selected diet, get the diet plan details
      if (selectedDietPlanId != null) {
        final dietPlans = await _dietService.getDietRecommendations();
        final selectedPlan = dietPlans.firstWhere(
          (plan) => plan.id == selectedDietPlanId,
          orElse: () => dietPlans.first,
        );

        setState(() {
          _selectedDietPlan = selectedPlan;
          _loadingDiet = false;
        });
      } else {
        setState(() => _loadingDiet = false);
      }
    } catch (e) {
      print('Error loading selected diet: $e');
      setState(() => _loadingDiet = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          transitionType: TransitionType.fade,
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
        Navigator.pop(context); // Close the modal first
        Navigator.push(
          context,
          CustomPageRoute(
            child: const ManageAccPage(),
            transitionType: TransitionType.fade,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(223, 77, 15, 1.0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color.fromRGBO(223, 77, 15, 1.0)),
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
        title: GestureDetector(
          onTap: () {
            // Update the selected index to home (0) and refresh UI
            setState(() {
              _selectedIndex = 0;
            });

            // This will update the navbar highlight
            if (_navbarKey.currentState != null) {
              _navbarKey.currentState!.handleLogoClick(context);
            }
          },
          child: Image.asset(
            'assets/Fitscale_LOGO.png',
            height: 80,
          ),
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
              _buildDietSummaryCard(),
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
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: Color.fromRGBO(223, 77, 15, 1.0),
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
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        showProfileModal: _showProfileModal,
        loadAndNavigateToRecommendations: _loadAndNavigateToRecommendations,
        key: _navbarKey,
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
            CustomPageRoute(
              child: const StepsPage(),
              transitionType: TransitionType.fade,
            ),
          );
        } else if (title.contains('kg')) {
          // Navigate to MeasureWeightPage when weight card is tapped
          Navigator.push(
            context,
            CustomPageRoute(
              child: const MeasureWeightPage(),
              transitionType: TransitionType.fade,
            ),
          ).then((_) {
            // Refresh data when returning from MeasureWeightPage
            _fetchUserData();
          });
        } else if (title == 'Set Diets!') {
          // Navigate to DietRecommendationsPage when diet card is tapped
          Navigator.push(
            context,
            CustomPageRoute(
              child: const DietRecommendationsPage(),
              transitionType: TransitionType.fade,
            ),
          );
        }
        // Add more conditions for other cards if needed
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color.fromRGBO(223, 77, 15, 1.0)),
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
            Icon(icon, color: const Color.fromRGBO(223, 77, 15, 1.0), size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDietSummaryCard() {
    return GestureDetector(
      onTap: () {
        if (_selectedDietPlan != null) {
          // Navigate to selected diet detail page if we have a selected diet
          Navigator.push(
            context,
            CustomPageRoute(
              child: SelectedDietPage(
                dietPlan: _selectedDietPlan!,
              ),
              transitionType: TransitionType.fade,
            ),
          ).then((_) {
            // Refresh diet data when returning
            _loadSelectedDiet();
          });
        } else {
          // Navigate to diet recommendations to select a diet
          Navigator.push(
            context,
            CustomPageRoute(
              child: const DietRecommendationsPage(),
              transitionType: TransitionType.fade,
            ),
          ).then((_) {
            // Refresh diet data when returning
            _loadSelectedDiet();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color.fromRGBO(223, 77, 15, 1.0)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _loadingDiet
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFFDF4D0F),
                  ),
                ),
              )
            : Row(
                children: [
                  // Diet information with "You are on:" text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You are on:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDietPlan != null
                              ? _selectedDietPlan!.name
                              : 'Set Diet!',
                          style: const TextStyle(
                            color: Color(0xFFDF4D0F),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Diet image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFDF4D0F),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _selectedDietPlan != null
                          ? _selectedDietPlan!.imageUrl.startsWith('http')
                              ? Image.network(
                                  _selectedDietPlan!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Color(0xFFDF4D0F),
                                        size: 30,
                                      ),
                                    );
                                  },
                                )
                              : Image.asset(
                                  _selectedDietPlan!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Color(0xFFDF4D0F),
                                        size: 30,
                                      ),
                                    );
                                  },
                                )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.restaurant,
                                color: Color(0xFFDF4D0F),
                                size: 30,
                              ),
                            ),
                    ),
                  ),
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
