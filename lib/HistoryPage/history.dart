import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'history_item.dart';
import '../SummaryPage/summary_page.dart';
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';
import '../navigation/custom_navbar.dart';
import '../screens/recommendations_page.dart';
import '../models/user_model.dart';
import '../utils/custom_page_route.dart';
import '../SummaryPage/manage_acc.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final WorkoutHistoryService _historyService;
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String selectedMonth = DateTime.now().month.toString();
  int selectedYear = 2025;
  int _selectedIndex = 2;
  List<WorkoutHistory> _workoutHistory = [];
  bool _isLoading = true;
  bool _loadingSteps = false;
  List<Map<String, dynamic>> _stepHistory = [];
  List<WorkoutHistory> _filteredWorkouts = [];
  final GlobalKey<CustomNavBarState> _navbarKey =
      GlobalKey<CustomNavBarState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = months[now.month - 1];
    selectedYear = now.year;
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _historyService.getWorkoutHistory();
      setState(() {
        _workoutHistory = history;
        _isLoading = false;
        _filterWorkoutsByMonth();
      });
    } catch (e) {
      print('Error loading workout history: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStepHistory() async {
    setState(() => _loadingSteps = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_tracking')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _stepHistory = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'steps': data['steps'] ?? 0,
            'date': (data['timestamp'] as Timestamp).toDate(),
            'calories': data['calories'] ?? 0,
            'distance': data['distance'] ?? 0.0,
          };
        }).toList();
        _loadingSteps = false;
      });
    } catch (e) {
      debugPrint('Error loading step history: $e');
      setState(() => _loadingSteps = false);
    }
  }

  void _filterWorkoutsByMonth() {
    if (_workoutHistory.isEmpty) {
      _filteredWorkouts = [];
      return;
    }

    final monthIndex = months.indexOf(selectedMonth) + 1;

    _filteredWorkouts = _workoutHistory.where((workout) {
      return workout.date.month == monthIndex &&
          workout.date.year == selectedYear;
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredStepHistory() {
    final monthIndex = months.indexOf(selectedMonth) + 1;
    return _stepHistory.where((step) {
      final stepDate = step['date'] as DateTime;
      return stepDate.month == monthIndex && stepDate.year == selectedYear;
    }).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const SummaryPage(),
          transitionType: TransitionType.fade,
        ),
      );
    } else if (index == 1) {
      // Navigate to RecommendationsPage through the loadAndNavigateToRecommendations function
      _loadAndNavigateToRecommendations();
    } else if (index == 1) {
      // Show profile modal
      _showProfileModal(context);
    }
    // No need to handle index 2 (current page)
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
                            backgroundColor: Color.fromRGBO(223, 77, 15, 0.2),
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

  // Add this method to handle year changes
  void _applyYearChange(int newYear) {
    setState(() {
      selectedYear = newYear;
      _filterWorkoutsByMonth();
    });
  }

  void _showMonthPicker() {
    int tempYear =
        selectedYear; // Temporary variable to track year changes in the modal

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Year selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () {
                          setModalState(() {
                            tempYear--;
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(223, 77, 15, 1.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$tempYear',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white),
                        onPressed: () {
                          setModalState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: months.length,
                      itemBuilder: (context, index) {
                        final bool isSelected =
                            months[index] == selectedMonth &&
                                tempYear == selectedYear;
                        return ListTile(
                          title: Text(
                            months[index],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color.fromRGBO(223, 77, 15, 1.0)
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            // Apply both month and year changes
                            setState(() {
                              selectedMonth = months[index];
                              selectedYear = tempYear; // Apply the year change
                              _filterWorkoutsByMonth();
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutHistoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_workoutHistory.isEmpty) {
      return const Center(
        child: Text(
          'No workout history available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_filteredWorkouts.isEmpty) {
      return Center(
        child: Text(
          'No workouts found for $selectedMonth $selectedYear',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredWorkouts.length,
      itemBuilder: (context, index) {
        final history = _filteredWorkouts[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(44, 44, 46, 1.0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(223, 77, 15, 1.0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    history.workoutName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: history.isCompleted
                          ? const Color.fromRGBO(223, 77, 15, 0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      history.isCompleted ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        color: history.isCompleted
                            ? const Color.fromRGBO(223, 77, 15, 1.0)
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                history.exerciseName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.timer,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${history.duration} min',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${history.setsCompleted}/${history.totalSets} sets',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy h:mm a').format(history.date),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              if (history.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  history.notes,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepHistoryList() {
    if (_loadingSteps) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredSteps = _getFilteredStepHistory();

    if (filteredSteps.isEmpty) {
      return const Center(
        child: Text(
          'No step history available for this month',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredSteps.length,
      itemBuilder: (context, index) {
        final stepData = filteredSteps[index];
        final steps = stepData['steps'] as int;
        final date = stepData['date'] as DateTime;
        final calories = stepData['calories'] as num;
        final distance = stepData['distance'] as num;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 30, 1.0),
            border: Border.all(
              color: const Color.fromRGBO(223, 77, 15, 1.0),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Steps Taken',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$steps',
                      style: const TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' Steps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color.fromRGBO(223, 77, 15, 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${calories.round()} kcal',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Color.fromRGBO(223, 77, 15, 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${distance.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityHistoryTable() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(44, 44, 46, 1.0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromRGBO(223, 77, 15, 1.0),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activities history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMonthPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(28, 28, 30, 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$selectedMonth $selectedYear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color.fromRGBO(28, 28, 30, 1.0)),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Steps'),
                        Tab(text: 'Workouts'),
                      ],
                      labelColor: Color.fromRGBO(223, 77, 15, 1.0),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color.fromRGBO(223, 77, 15, 1.0),
                    ),
                    const Divider(
                        height: 1, color: Color.fromRGBO(28, 28, 30, 1.0)),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildStepHistoryList(),
                          _buildWorkoutHistoryList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          color: Color(0xFFDF4D0F),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Track your activities',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });

                      // Use the navbar's handler for consistent behavior
                      if (_navbarKey.currentState != null) {
                        _navbarKey.currentState!.handleLogoClick(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          CustomPageRoute(
                            child: const SummaryPage(),
                            transitionType: TransitionType.fade,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/Fitscale_LOGO.png',
                        height: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: _buildActivityHistoryTable(),
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
        key: _navbarKey,
      ),
    );
  }
}
