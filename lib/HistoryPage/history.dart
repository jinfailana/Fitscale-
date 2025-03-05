import 'package:flutter/material.dart';
import 'history_item.dart';
import '../SummaryPage/summary_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Add month selection logic
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  // Initialize with current month and fixed year
  String selectedMonth = DateTime.now().month.toString();
  int selectedYear = 2025;
  int selectedTabIndex = 0;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    // Convert the month number to month name
    selectedMonth = months[DateTime.now().month - 1];
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(child: const SummaryPage()),
      );
    } else if (index == 3) {
      // Show profile modal
      // You might want to extract this to a shared utility class
      _showProfileModal(context);
    }
    // Add other navigation cases as needed
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Profile settings and options will go here',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonthPicker() {
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
                  // Year display (not selectable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(223, 77, 15, 1.0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '2025',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Month selection
                  Expanded(
                    child: ListView.builder(
                      itemCount: months.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = months[index] == selectedMonth;
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
                            setState(() {
                              selectedMonth = months[index];
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

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(_selectedIndex == index ? 15 : 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // History title and subtitle
              const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
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
              const SizedBox(height: 16),
              
              // Activity History Table
              Expanded(
                child: _buildActivityHistoryTable(),
              ),
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

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHistoryTable() {
    return Container(
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
          // Header with title and date selector
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const Divider(
            height: 1,
            color: Color.fromRGBO(28, 28, 30, 1.0),
          ),
          // Activity type tabs - Centered
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Workout', 0),
                      const SizedBox(width: 24),
                      _buildTabButton('Steps', 1),
                      const SizedBox(width: 24),
                      _buildTabButton('Diet', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color.fromRGBO(28, 28, 30, 1.0),
          ),
          // Placeholder for future activity data - Centered
          Expanded(
            child: Center(
              child: Text(
                'No ${selectedTabIndex == 0 ? 'workout' : selectedTabIndex == 1 ? 'steps' : 'diet'} history available',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
