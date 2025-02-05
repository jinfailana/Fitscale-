import 'package:flutter/material.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) {
      _showProfileModal(context);
    }
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index ? const Color.fromRGBO(223, 77, 15, 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(_selectedIndex == index ? 15 : 10),
          border: Border.all(
            color: _selectedIndex == index ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon, color: _selectedIndex == index ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white54),
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
                _buildProfileOption(Icons.person, 'Jin Failana', 'jinalipio2004@gmail.com'),
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
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/Fitscale_LOGO.png', // Replace with your logo asset path
          height: 85,
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Text(
              'Welcome, [username]',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.person, color: Color.fromRGBO(223, 77, 15, 1.0)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 1),
            const Text(
              'Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            _buildAnimatedSummaryCard('Set Step Goal', 'Daily goal: No goal yet', Icons.directions_walk),
            _buildAnimatedSummaryCard('0kg', 'Current Weight', Icons.monitor_weight),
            _buildAnimatedSummaryCard('Set Diets!', 'Mark your meals today!', Icons.restaurant),
            const SizedBox(height: 20),
            const Text(
              'Recent Workout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                border: Border.all(color: Color.fromRGBO(223, 77, 15, 0.8), width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'No Workouts Found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  Widget _buildAnimatedSummaryCard(String title, String subtitle, IconData icon) {
    return AnimatedContainer(
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  //color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(icon, color: Color.fromRGBO(223, 77, 15, 1.0)),
        ],
      ),
    );
  }
}

class AnimatedContainerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedContainerWidget({super.key, required this.child, required this.onTap});

  @override
  AnimatedContainerWidgetState createState() => AnimatedContainerWidgetState();
}

class AnimatedContainerWidgetState extends State<AnimatedContainerWidget> with SingleTickerProviderStateMixin {
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
