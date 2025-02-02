import 'package:flutter/material.dart';
import 'set_goal.dart';

class SelectGenderPage extends StatefulWidget {
  const SelectGenderPage({super.key});

  @override
  State<SelectGenderPage> createState() => _SelectGenderPageState();
}

class _SelectGenderPageState extends State<SelectGenderPage> {
  String? selectedGender;

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
            Navigator.pushReplacementNamed(context, '/login');
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
                'GENDER',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Allows us to suggest goods that align with typical user preferences',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _genderButton('Male', Icons.male),
                  const SizedBox(width: 20),
                  _genderButton('Female', Icons.female),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: selectedGender != null ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetGoalPage()),
                    );
                  } : null,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String gender, IconData icon) {
    bool isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Animation duration
            width: 170,
            height: 400,
            decoration: BoxDecoration(
              color: isSelected ? const Color.fromRGBO(223, 77, 15, 0.2) : Colors.transparent,
              border: Border.all(
                color: const Color.fromRGBO(223, 77, 15, 1.0),
                width: isSelected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 5,
                  offset: const Offset(0, 10), // 10% of 400
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: gender == 'Male' ? 2.35000:0,// Rotate 45 degrees (0.785398 radians) for male
                    child: Icon(
                      icon,
                      size: 140,
                      color: isSelected
                          ? const Color.fromRGBO(223, 77, 15, 1.0)
                          : const Color.fromRGBO(51, 50, 50, 1.0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gender,
                    style: TextStyle(
                      color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}