import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            children: [
              const Text(
                'Select Your Gender',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedGender = 'Male';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender == 'Male' ? Colors.blue : Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white54, width: 2),
                      ),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.male, size: 80, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text(
                          'Male',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedGender = 'Female';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender == 'Female' ? Colors.pink : Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white54, width: 2),
                      ),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.female, size: 80, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text(
                          'Female',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: selectedGender != null ? () {
                  // Handle next button press
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
