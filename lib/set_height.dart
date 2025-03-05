import 'package:flutter/material.dart';
import 'set_weight.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

class SetHeightPage extends StatefulWidget {
  const SetHeightPage({super.key});

  @override
  State<SetHeightPage> createState() => _SetHeightPageState();
}

class _SetHeightPageState extends State<SetHeightPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;
  
  String unit = 'ft';
  String? selectedHeight;
  final List<String> heightsFt = List.generate(59, (index) {
    // 59 positions from 3'3" to 8'2"
    int totalInches = 39 + index; // Start at 39" (3'3") and go up to 98" (8'2")
    int feet = totalInches ~/ 12;
    int inches = totalInches % 12;
    return '$feet ft $inches in';
  });
  // For metric, equivalent range would be approximately 100cm to 249cm
  final List<String> heightsCm =
      List.generate(150, (index) => '${100 + index} cm');

  // Convert height string to centimeters
  double _convertToCm(String height) {
    if (unit == 'cm') {
      return double.parse(height.split(' ')[0]);
    } else {
      // Convert ft/in to cm
      final parts = height.split(' ');
      final feet = int.parse(parts[0]);
      final inches = int.parse(parts[2]);
      return (feet * 30.48) + (inches * 2.54); // Convert to cm
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        title: const Text('Height'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(223, 77, 15, 1.0)),
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
                'Height',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Helps us customize your fitness plan based on your body structure',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _unitButton('Cm'),
                  const SizedBox(width: 10),
                  _unitButton('Ft'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: unit == 'ft' ? heightsFt.length : heightsCm.length,
                  itemBuilder: (context, index) {
                    return _heightButton(
                        unit == 'ft' ? heightsFt[index] : heightsCm[index]);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: selectedHeight != null
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            final userId = _authService.getCurrentUserId();
                            if (userId == null) throw Exception('User not logged in');

                            // Convert height to cm and save
                            final heightInCm = _convertToCm(selectedHeight!);
                            await _userService.updateMetrics(
                              userId,
                              height: heightInCm,
                            );

                            // Navigate to weight page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SetWeightPage(),
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
                        }
                      : null,
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

  Widget _heightButton(String height) {
    bool isSelected = selectedHeight == height;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedHeight = height;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color.fromRGBO(223, 77, 15, 1.0)
                : Colors.transparent,
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
        child: Center(
          child: Text(
            height,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromRGBO(223, 77, 15, 1.0)
                  : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
