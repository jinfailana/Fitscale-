import 'package:flutter/material.dart';
import '../SummaryPage/summary_page.dart';
import '../HistoryPage/history.dart';
import '../utils/custom_page_route.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Set to 1 for Workouts tab
  int _selectedTabIndex =
      0; // 0: Recommended, 1: My Workouts, 2: Other Workouts
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation
    if (index == 0) {
      // Navigate to Summary page
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const SummaryPage(),
          transitionType: TransitionType.fade,
        ),
      );
    } else if (index == 2) {
      // Navigate to History page
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const HistoryPage(),
          transitionType: TransitionType.fade,
        ),
      );
    } else if (index == 3) {
      // Navigate to Profile/Me page
      // Add your profile page navigation here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECOMMENDED WORKOUT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Let\'s start your activities!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            // Tab Bar
            SizedBox(
              height: 40,
              child: TabBar(
                controller: _tabController,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3.0,
                    color: Color.fromRGBO(223, 77, 15, 1.0),
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                labelColor: const Color.fromRGBO(223, 77, 15, 1.0),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Recommended Workouts'),
                  Tab(text: 'My Workouts'),
                  Tab(text: 'Other Workouts'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Recommended Workouts Tab
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildWorkoutCard(
                          'Classic Workout',
                          'A classic workout combines strength training, cardio, and flexibility exercises.',
                          'assets/images/classic_workout.png',
                        ),
                        _buildWorkoutCard(
                          'Abs Workout',
                          'An abs workout targets the core muscles for strength and stability.',
                          'assets/images/abs_workout.png',
                        ),
                        _buildWorkoutCard(
                          'Arm Workout',
                          'An arm workout focuses on strengthening the biceps, triceps, and shoulders.',
                          'assets/images/arm_workout.png',
                        ),
                      ],
                    ),
                  ),
                  // My Workouts Tab
                  const Center(
                    child: Text(
                      'No custom workouts yet.\nCreate your own workout routine!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  // Other Workouts Tab
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildWorkoutCard(
                          'Leg Workout',
                          'A leg workout focuses on strengthening the quadriceps, hamstrings, and calves.',
                          'assets/images/leg_workout.png',
                        ),
                        _buildWorkoutCard(
                          'Back Workout',
                          'A back workout targets the latissimus dorsi, rhomboids, and trapezius muscles.',
                          'assets/images/back_workout.png',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildWorkoutCard(String title, String description, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 45, 45, 1.0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color.fromRGBO(223, 77, 15, 1.0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Workout image as background
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
