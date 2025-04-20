import 'package:flutter/material.dart';
import 'act_level.dart';
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
  bool _isLoading = false;
  
  String unit = 'kg';
  double? selectedWeight;
  final List<double> weightsKg =
      List.generate(221, (index) => (30 + index).toDouble());
  final List<double> weightsLbs =
      List.generate(485, (index) => (66 + index).toDouble());

  // Convert weight to kilograms
  double _convertToKg(double weight) {
    if (unit == 'kg') {
      return weight;
    } else {
      return weight * 0.453592; // Convert lbs to kg
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
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight',
                      style: TextStyle(
                        color: Color.fromRGBO(223, 77, 15, 1.0),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
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
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount:
                        unit == 'kg' ? weightsKg.length : weightsLbs.length,
                    itemBuilder: (context, index) {
                      double weight =
                          unit == 'kg' ? weightsKg[index] : weightsLbs[index];
                      return _weightButton(weight);
                    },
                  ),
                ),
                const Spacer(flex: 1),
                SizedBox(
                  width: 350,
                  child: ElevatedButton(
                    onPressed: selectedWeight != null
                        ? () async {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              final userId = _authService.getCurrentUserId();
                              if (userId == null) {
                                throw Exception('User not logged in');
                              }

                              // Convert to kg and save
                              final weightInKg = _convertToKg(selectedWeight!);
                              await _userService.updateMetrics(
                                userId,
                                weight: weightInKg,
                              );

                              // Navigate to activity level page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ActivityLevelPage(),
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
                            'Confirm',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 80),
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
          unit = unitType.toLowerCase();
          selectedWeight = null; // Reset selection when changing units
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

  Widget _weightButton(double weight) {
    bool isSelected = selectedWeight == weight;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWeight = weight;
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
            '${weight.toStringAsFixed(1)}${unit.toLowerCase()}',
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
