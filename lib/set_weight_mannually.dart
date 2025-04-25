import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'act_level.dart';  // Add this import for the next page
import 'services/auth_service.dart';
import 'services/user_service.dart';

class SetWeightManuallyPage extends StatefulWidget {
  const SetWeightManuallyPage({super.key});

  @override
  State<SetWeightManuallyPage> createState() => _SetWeightManuallyPageState();
}

class _SetWeightManuallyPageState extends State<SetWeightManuallyPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _weightController = TextEditingController(text: '65.0');
  bool _isLoading = false;
  String unit = 'kg';

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Convert weight to kg
  double _convertToKg(String weight) {
    if (weight.isEmpty) return 0.0;
    double? value = double.tryParse(weight);
    if (value == null) return 0.0;
    
    if (unit == 'kg') {
      return value;
    } else {
      // Convert lbs to kg
      return value * 0.453592;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Weight',
                  style: TextStyle(
                    color: Color.fromRGBO(223, 77, 15, 1.0),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your current weight to track your progress',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
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
                const SizedBox(height: 60),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      TextField(
                        controller: _weightController,
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
                      if (_weightController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your weight')),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      try {
                        final userId = _authService.getCurrentUserId();
                        if (userId == null) throw Exception('User not logged in');

                        final weightInKg = _convertToKg(_weightController.text);
                        if (weightInKg <= 0) {
                          throw Exception('Please enter a valid weight');
                        }
                        
                        await _userService.updateMetrics(userId, weight: weightInKg);
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ActivityLevelPage()),
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
          
          // Convert the current weight when switching units
          if (_weightController.text.isNotEmpty) {
            double? currentWeight = double.tryParse(_weightController.text);
            if (currentWeight != null) {
              if (oldUnit == 'kg' && unit == 'lbs') {
                // Convert from kg to lbs
                _weightController.text = (currentWeight / 0.453592).toStringAsFixed(1);
              } else if (oldUnit == 'lbs' && unit == 'kg') {
                // Convert from lbs to kg
                _weightController.text = (currentWeight * 0.453592).toStringAsFixed(1);
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