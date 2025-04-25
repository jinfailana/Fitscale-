import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _heightController = TextEditingController(text: '170');
  bool _isLoading = false;
  String unit = 'cm';

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  // Convert height to cm
  double _convertToCm(String height) {
    if (height.isEmpty) return 0.0;
    double? value = double.tryParse(height);
    if (value == null) return 0.0;
    
    if (unit == 'cm') {
      return value;
    } else {
      // Convert feet to cm
      return value * 30.48;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
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
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _unitButton('Cm'),
                  const SizedBox(width: 10),
                  _unitButton('Ft'),
                ],
              ),
              const SizedBox(height: 60),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          color: const Color.fromRGBO(223, 77, 15, 1.0).withOpacity(0.5),
                        ),
                        suffixText: unit,
                        suffixStyle: const TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 24,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                    Container(
                      height: 2,
                      color: const Color.fromRGBO(223, 77, 15, 1.0),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_heightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your height')),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      final userId = _authService.getCurrentUserId();
                      if (userId == null) throw Exception('User not logged in');

                      final heightInCm = _convertToCm(_heightController.text);
                      if (heightInCm <= 0) {
                        throw Exception('Please enter a valid height');
                      }
                      
                      await _userService.updateMetrics(userId, height: heightInCm);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SetWeightPage()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
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
              const SizedBox(height: 40),
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
          String oldUnit = unit;
          unit = unitType.toLowerCase();
          
          // Convert the current height when switching units
          if (_heightController.text.isNotEmpty) {
            double? currentHeight = double.tryParse(_heightController.text);
            if (currentHeight != null) {
              if (oldUnit == 'cm' && unit == 'ft') {
                // Convert from cm to feet
                _heightController.text = (currentHeight / 30.48).toStringAsFixed(1);
              } else if (oldUnit == 'ft' && unit == 'cm') {
                // Convert from feet to cm
                _heightController.text = (currentHeight * 30.48).toStringAsFixed(1);
              }
            }
          }
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
            color: isSelected ? Colors.white : const Color.fromRGBO(223, 77, 15, 1.0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
