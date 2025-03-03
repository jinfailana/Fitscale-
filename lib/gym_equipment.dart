import 'package:flutter/material.dart';
import 'allset_page.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

class GymEquipmentPage extends StatefulWidget {
  const GymEquipmentPage({super.key});

  @override
  GymEquipmentPageState createState() => GymEquipmentPageState();
}

class GymEquipmentPageState extends State<GymEquipmentPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  String selectedOption = 'Nope, Bodyweight exercise only';

  final List<Map<String, dynamic>> equipmentOptions = [
    {
      'icon': Icons.accessibility_new,
      'title': 'Nope, Bodyweight\nexercise only',
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Yes, Gym exercise\nare also needed',
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
              'Do you have any gym equipments',
              style: TextStyle(
                color: Color.fromRGBO(223, 77, 15, 1.0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us tailor workouts sessions to the equipment you have access to.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: equipmentOptions.length,
                itemBuilder: (context, index) {
                  return _equipmentOptionButton(index);
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

                      // Save gym equipment preference
                      await _userService.updateGymEquipment(
                        userId,
                        [selectedOption],
                      );

                      // Navigate to all set page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllSetPage(),
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

  Widget _equipmentOptionButton(int index) {
    bool isSelected = selectedOption == equipmentOptions[index]['title'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = equipmentOptions[index]['title'];
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
            Expanded(
              child: Text(
                equipmentOptions[index]['title'],
                style: TextStyle(
                  color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              equipmentOptions[index]['icon'],
              color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
} 