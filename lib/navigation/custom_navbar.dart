import 'package:flutter/material.dart';
import '../SummaryPage/summary_page.dart';
import '../HistoryPage/history.dart';
import '../screens/recommendations_page.dart';
import '../models/user_model.dart';
import '../utils/custom_page_route.dart';
import '../SummaryPage/manage_acc.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(BuildContext) showProfileModal;
  final Function() loadAndNavigateToRecommendations;

  const CustomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.showProfileModal,
    required this.loadAndNavigateToRecommendations,
  }) : super(key: key);

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon,
            color: selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.white54),
      ),
      label: label,
    );
  }

  void _navigateToManageAccount(BuildContext context) {
    Navigator.push(
      context,
      CustomPageRoute(
        child: const ManageAccPage(),
        transitionType: TransitionType.bottomToTop,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
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
        currentIndex: selectedIndex,
        onTap: (index) {
          // Skip navigation if already on the selected tab
          if (index == selectedIndex && index != 3) {
            return;
          }
          
          // First call the parent's onItemTapped to update the state
          onItemTapped(index);
          
          // Handle navigation based on the selected index
          if (index == 2 && selectedIndex != 2) {
            Navigator.pushReplacement(
              context,
              CustomPageRoute(
                child: const HistoryPage(),
                transitionType: selectedIndex < 2 
                    ? TransitionType.rightToLeft 
                    : TransitionType.leftToRight,
              ),
            );
          } else if (index == 3) {
            // Always show the profile modal when the "Me" tab is clicked
            showProfileModal(context);
          } else if (index == 1 && selectedIndex != 1) {
            // Use the provided function to load and navigate to recommendations
            loadAndNavigateToRecommendations();
          } else if (index == 0 && selectedIndex != 0) {
            Navigator.pushReplacement(
              context,
              CustomPageRoute(
                child: const SummaryPage(),
                transitionType: TransitionType.leftToRight,
              ),
            );
          }
        },
      ),
    );
  }
} 