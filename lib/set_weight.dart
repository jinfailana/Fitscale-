import 'package:flutter/material.dart';
import 'set_weight_mannually.dart';

class SetWeightPage extends StatefulWidget {
  const SetWeightPage({super.key});

  @override
  State<SetWeightPage> createState() => _SetWeightPageState();
}

class _SetWeightPageState extends State<SetWeightPage> {
  String unit = 'kg';
  double weight = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weight',
                    style: TextStyle(
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete this to calculate your BMI and recommend your workouts and types of diets',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _unitButton('Kg'),
                  const SizedBox(width: 10),
                  _unitButton('Lbs'),
                ],
              ),
              const Spacer(flex: 1),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromRGBO(223, 77, 15, 1.0),
                        width: 2,
                      ),
                    ),
                  ),
                  Text(
                    '${weight.toStringAsFixed(1)}${unit.toLowerCase()}',
                    style: const TextStyle(
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect to smart scale',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SetWeightManuallyPage()),
                  );
                },
                child: const Text(
                  'Set Weight Manually',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to next page
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
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitButton(String unitType) {
    bool isSelected = unit == unitType.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          unit = unitType.toLowerCase();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(223, 77, 15, 1.0)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromRGBO(223, 77, 15, 1.0),
          ),
        ),
        child: Text(
          unitType,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : const Color.fromRGBO(223, 77, 15, 1.0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
