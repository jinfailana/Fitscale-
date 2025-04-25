import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'set_goal.dart';

class SelectGenderPage extends StatefulWidget {
  const SelectGenderPage({super.key});

  @override
  State<SelectGenderPage> createState() => _SelectGenderPageState();
}

class _SelectGenderPageState extends State<SelectGenderPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String? selectedGender;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
        elevation: 0,
        
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),
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
                SizedBox(height: screenHeight * 0.04),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth - 48,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                              _genderButton('Male', Icons.male, screenHeight),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _genderButton(
                              'Female', Icons.female, screenHeight),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.85,
                    child: ElevatedButton(
                      onPressed: selectedGender != null
                          ? () async {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final userId = _authService.getCurrentUserId();
                                if (userId == null) throw Exception('User not logged in');

                                // Save gender
                                await _userService.updateGender(userId, selectedGender!);

                                // Navigate to next page
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SetGoalPage(),
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
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withAlpha(50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
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
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String gender, IconData icon, double screenHeight) {
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
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: screenHeight * 0.45,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromRGBO(223, 77, 15, 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: const Color.fromRGBO(223, 77, 15, 1.0),
                width: isSelected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 5,
                  offset: Offset(0, screenHeight * 0.01),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.2,
                  child: Center(
                    child: Transform.rotate(
                      angle: gender == 'Male' ? 2.35000 : 0,
                      child: Icon(
                        icon,
                        size: screenHeight * 0.15,
                        color: isSelected
                            ? const Color.fromRGBO(223, 77, 15, 1.0)
                            : const Color.fromRGBO(51, 50, 50, 1.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  gender,
                  style: TextStyle(
                    color: isSelected
                        ? const Color.fromRGBO(223, 77, 15, 1.0)
                        : Colors.white,
                    fontSize: screenHeight * 0.022,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: screenHeight * 0.01,
              right: screenHeight * 0.01,
              child: Icon(
                Icons.check_circle,
                color: const Color.fromRGBO(223, 77, 15, 1.0),
                size: screenHeight * 0.03,
              ),
            ),
        ],
      ),
    );
  }
}
