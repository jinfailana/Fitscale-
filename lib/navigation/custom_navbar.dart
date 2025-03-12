import 'package:flutter/material.dart';
import '../SummaryPage/summary_page.dart';
import '../HistoryPage/history.dart';
import '../screens/recommendations_page.dart';
import '../models/user_model.dart';
import '../utils/custom_page_route.dart';
import '../SummaryPage/manage_acc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNavBar extends StatefulWidget {
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

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  String _cachedUsername = 'User';
  String _cachedEmail = '';
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch user data when the navbar is created
    _prefetchUserData();
  }

  Future<void> _prefetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          setState(() {
            _cachedUsername = doc['username'] ?? 'User';
            _cachedEmail = user.email ?? '';
            _isDataLoaded = true;
          });
        }
      } catch (e) {
        print('Error pre-fetching user data: $e');
      }
    }
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: widget.selectedIndex == index
              ? const Color.fromRGBO(223, 77, 15, 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(widget.selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: widget.selectedIndex == index
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon,
            color: widget.selectedIndex == index
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

  // Show profile modal with immediate display of user data
  void _handleProfileTap(BuildContext context) {
    // If we have cached data, show it immediately
    if (_isDataLoaded) {
      _showCachedProfileModal(context);
    } else {
      // Show loading indicator while fetching data
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          // Try to fetch data and update the modal
          _prefetchUserData().then((_) {
            Navigator.pop(context);
            _showCachedProfileModal(context);
          });
          
          // Return a loading container
          return Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(28, 28, 30, 1.0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Color(0xFFDF4D0F),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // Show profile modal with cached data
  void _showCachedProfileModal(BuildContext context) {
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
                        CircleAvatar(
                          backgroundColor: const Color.fromRGBO(223, 77, 15, 0.2),
                          radius: 20,
                          child: const Icon(
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
                                _cachedUsername,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cachedEmail,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.devices,
                          color: Color(0xFFDF4D0F),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'My Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        currentIndex: widget.selectedIndex,
        onTap: (index) {
          // Skip navigation if already on the selected tab
          if (index == widget.selectedIndex && index != 3) {
            return;
          }
          
          // First call the parent's onItemTapped to update the state
          widget.onItemTapped(index);
          
          // Handle navigation based on the selected index
          if (index == 2 && widget.selectedIndex != 2) {
            Navigator.pushReplacement(
              context,
              CustomPageRoute(
                child: const HistoryPage(),
                transitionType: widget.selectedIndex < 2 
                    ? TransitionType.rightToLeft 
                    : TransitionType.leftToRight,
              ),
            );
          } else if (index == 3) {
            // Use our new method for immediate display of user data
            _handleProfileTap(context);
          } else if (index == 1 && widget.selectedIndex != 1) {
            // Use the provided function to load and navigate to recommendations
            widget.loadAndNavigateToRecommendations();
          } else if (index == 0 && widget.selectedIndex != 0) {
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