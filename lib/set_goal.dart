import 'package:flutter/material.dart';
import 'birth_year.dart';

class SetGoalPage extends StatefulWidget {
  const SetGoalPage({super.key});

  @override
  State<SetGoalPage> createState() => _SetGoalPageState();
}

class _SetGoalPageState extends State<SetGoalPage> {
  String? selectedGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOAL',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help us recommend personalized plans based on your fitness objectives',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              _goalButton('Lose Weight', Icons.fitness_center),
              const SizedBox(height: 20),
              _goalButton('Build Muscle', Icons.fitness_center),
              const SizedBox(height: 20),
              _goalButton('Stay Fit', Icons.fitness_center),
              const SizedBox(height: 40),
              SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: selectedGoal != null ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BirthYearPage()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: Colors.black.withAlpha(128),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalButton(String goal, IconData icon) {
    bool isSelected = selectedGoal == goal;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = goal;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? 350 : 320,
        padding: const EdgeInsets.all(16),
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
              offset: const Offset(0, 8),
            ),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.split(' ')[0],
              style: TextStyle(
                color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              goal.split(' ')[1],
              style: TextStyle(
                color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}