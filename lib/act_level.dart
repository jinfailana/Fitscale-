import 'package:flutter/material.dart';

class ActivityLevelPage extends StatefulWidget {
  const ActivityLevelPage({super.key});

  @override
  State<ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  int? selectedLevel;

  final List<Map<String, dynamic>> activityLevels = [
    {
      'icon': Icons.directions_walk,
      'title': 'Sedentary',
      'description': 'Little to no exercise',
    },
    {
      'icon': Icons.directions_run,
      'title': 'Lightly Active',
      'description': 'Light exercise 1-3 days/week',
    },
    {
      'icon': Icons.directions_run,
      'title': 'Moderately Active',
      'description': 'Moderate exercise 3-5 days/week',
    },
    {
      'icon': Icons.directions_run,
      'title': 'Very Active',
      'description': 'Hard exercise 6-7 days/week',
    },
    {
      'icon': Icons.directions_run,
      'title': 'Extremely Active',
      'description': 'Very hard exercise & physical job',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Level',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Helps us determine your daily calorie needs',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: activityLevels.length,
                  itemBuilder: (context, index) {
                    return _activityLevelButton(index);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 350,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/pref_workout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 5,
                      shadowColor: Colors.black.withAlpha(50),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityLevelButton(int index) {
    bool isSelected = selectedLevel == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color.fromRGBO(223, 77, 15, 0.2) : Colors.transparent,
                border: Border.all(
                  color: const Color.fromRGBO(223, 77, 15, 1.0),
                  width: 2,
                ),
              ),
              child: Icon(
                activityLevels[index]['icon'],
                color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityLevels[index]['title'],
                    style: TextStyle(
                      color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityLevels[index]['description'],
                    style: const TextStyle(
                      color: Colors.white54,
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