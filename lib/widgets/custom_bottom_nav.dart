import 'package:flutter/material.dart';
import '../SummaryPage/summary_page.dart';
import '../HistoryPage/history.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 1.0)
              : Colors.white54,
        ),
      ),
      label: label,
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
        onTap: onItemTapped,
      ),
    );
  }
} 