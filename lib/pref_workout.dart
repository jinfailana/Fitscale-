import 'package:flutter/material.dart';
import 'work_place.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

class PrefWorkoutPage extends StatefulWidget {
  const PrefWorkoutPage({super.key});

  @override
  PrefWorkoutPageState createState() => PrefWorkoutPageState();
}

class PrefWorkoutPageState extends State<PrefWorkoutPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  String selectedLevel = 'Beginner';

  final List<Map<String, dynamic>> workoutLevels = [
    {
      'title': 'Beginner',
      'description': 'Best for newbies or just starting',
    },
    {
      'title': 'Intermediate',
      'description': 'For those with some experience',
    },
    {
      'title': 'Advanced',
      'description': 'For experienced individuals',
    },
    {
      'title': 'Expert',
      'description': 'For top-level athletes',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromRGBO(223, 77, 15, 1.0)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout',
              style: TextStyle(
                color: Color.fromRGBO(223, 77, 15, 1.0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us recommend exercises that match your fitness experience and expectations.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: workoutLevels.length,
                itemBuilder: (context, index) {
                  return _workoutLevelButton(index);
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final userId = _authService.getCurrentUserId();
                      if (userId == null) {
                        throw Exception('User not logged in');
                      }

                      // Save preferred workout level
                      await _userService.updatePrefWorkout(
                        userId,
                        [selectedLevel],
                      );

                      // Navigate to work place page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkPlacePage(),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
    );
  }

  Widget _workoutLevelButton(int index) {
    bool isSelected = selectedLevel == workoutLevels[index]['title'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = workoutLevels[index]['title'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[850] : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutLevels[index]['title'],
                  style: TextStyle(
                    color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workoutLevels[index]['description'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color.fromRGBO(223, 77, 15, 1.0),
              ),
          ],
        ),
      ),
    );
  }
}
