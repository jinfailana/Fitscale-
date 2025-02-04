import 'package:flutter/material.dart';

class WorkPlacePage extends StatefulWidget {
  const WorkPlacePage({super.key});

  @override
  WorkPlacePageState createState() => WorkPlacePageState();
}

class WorkPlacePageState extends State<WorkPlacePage> {
  String selectedPlace = 'Home';

  final List<Map<String, dynamic>> workoutPlaces = [
    {
      'icon': Icons.home,
      'title': 'Home',
      'description': 'No gym, creative workouts at home',
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Gym',
      'description': 'Prefer a gym setting with equipment',
    },
    {
      'icon': Icons.meeting_room,
      'title': 'Outdoor',
      'description': 'Prefers outdoor workouts',
    },
    {
      'icon': Icons.shuffle,
      'title': 'Mixed',
      'description': 'Home, gym and outdoor workouts',
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Place',
              style: TextStyle(
                color: Color.fromRGBO(223, 77, 15, 1.0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Help us suggest exercises that fit your workout space preferences.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: workoutPlaces.length,
                itemBuilder: (context, index) {
                  return _workoutPlaceButton(index);
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/gym_equipment');
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _workoutPlaceButton(int index) {
    bool isSelected = selectedPlace == workoutPlaces[index]['title'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlace = workoutPlaces[index]['title'];
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
            Row(
              children: [
                Icon(
                  workoutPlaces[index]['icon'],
                  color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutPlaces[index]['title'],
                      style: TextStyle(
                        color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workoutPlaces[index]['description'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
          ],
        ),
      ),
    );
  }
} 