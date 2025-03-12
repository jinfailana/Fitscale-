import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation/custom_navbar.dart';
import '../utils/custom_page_route.dart';
import '../screens/recommendations_page.dart';
import '../HistoryPage/history.dart';
import '../models/user_model.dart';
import '../firstlogin.dart';

class ManageAccPage extends StatefulWidget {
  const ManageAccPage({super.key});

  @override
  State<ManageAccPage> createState() => _ManageAccPageState();
}

class _ManageAccPageState extends State<ManageAccPage> {
  String username = '';
  String signInMethod = '';
  int _selectedIndex = 3; // Set to 3 for the "Me" tab

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'] ?? 'User';
            signInMethod = userDoc['signInMethod'] ?? 'email';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index != 3) { // If not on the current "Me" tab
      Navigator.pop(context); // Pop the current page first
      
      if (index == 0) {
        // Navigate to SummaryPage is handled by popping back
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          CustomPageRoute(child: const HistoryPage()),
        );
      }
    }
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 30, 1.0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 75.0),
                      child: const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color.fromRGBO(223, 77, 15, 1.0),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileModalOption(
                  Icons.person, 
                  username, 
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    // Already on account page, no need to navigate
                  },
                ),
                const SizedBox(height: 10),
                _buildProfileModalOption(
                  Icons.devices, 
                  'My Device', 
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    // Handle device settings navigation if needed
                  },
                ),
                const SizedBox(height: 10),
                _buildProfileModalOption(
                  Icons.logout, 
                  'Log Out', 
                  '',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileModalOption(
    IconData icon, 
    String title, 
    String subtitle, 
    {required Function() onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFDF4D0F)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAndNavigateToRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please log in to view recommendations')),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print('User document does not exist');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Validate required date fields
      if (userData['createdAt'] == null || userData['updatedAt'] == null) {
        print('Missing date fields in user data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user profile data')),
        );
        return;
      }

      final userModel = UserModel(
        id: user.uid,
        email: userData['email'] ?? '',
        gender: userData['gender'],
        goal: userData['goal'],
        age: userData['age'],
        weight: userData['weight'] != null
            ? (userData['weight'] as num).toDouble()
            : null,
        height: userData['height'] != null
            ? (userData['height'] as num).toDouble()
            : null,
        activityLevel: userData['activityLevel'],
        workoutPlace: userData['workoutPlace'],
        preferredWorkouts: userData['preferredWorkouts'] != null
            ? List<String>.from(userData['preferredWorkouts'])
            : null,
        gymEquipment: userData['gymEquipment'] != null
            ? List<String>.from(userData['gymEquipment'])
            : null,
        setupCompleted: userData['setupCompleted'] ?? false,
        currentSetupStep: userData['currentSetupStep'] ?? 'registered',
        createdAt: userData['createdAt'] is String
            ? DateTime.parse(userData['createdAt'])
            : (userData['createdAt'] as Timestamp).toDate(),
        updatedAt: userData['updatedAt'] is String
            ? DateTime.parse(userData['updatedAt'])
            : (userData['updatedAt'] as Timestamp).toDate(),
      );

      Navigator.push(
        context,
        CustomPageRoute(
          child: RecommendationsPage(user: userModel),
        ),
      );
    } catch (e, stackTrace) {
      print('Error loading recommendations: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load recommendations: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDF4D0F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Spacer(),
            Text(
              'Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(flex: 2), // Adjust this to center the title
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 90),
            _buildAccountOption(context, 'Name', username),
            const SizedBox(height: 40),
            _buildAccountOption(context, 'Change Password', ''),
            const SizedBox(height: 120),
            ElevatedButton(
              onPressed: () => _showLogoutConfirmationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDF4D0F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        showProfileModal: _showProfileModal,
        loadAndNavigateToRecommendations: _loadAndNavigateToRecommendations,
      ),
    );
  }

  Widget _buildAccountOption(
      BuildContext context, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        if (title == 'Name') {
          _showChangeUsernameDialog(context);
        } else if (title == 'Change Password') {
          _handleChangePassword(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _showChangeUsernameDialog(BuildContext context) {
    final usernameController = TextEditingController(text: username);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(28, 28, 30, 1.0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDF4D0F), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDF4D0F)),
                    ),
                    child: TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(60, 60, 62, 1.0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: Color(0xFFDF4D0F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final newUsername = usernameController.text.trim();
                            if (newUsername.isNotEmpty && newUsername != username) {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({'username': newUsername});
                                  setState(() {
                                    username = newUsername;
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Username changed successfully.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error changing username: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to change username: $e'),
                                  ),
                                );
                              }
                            } else if (newUsername.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username cannot be empty'),
                                ),
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDF4D0F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'SAVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleChangePassword(BuildContext context) {
    if (signInMethod == 'google') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changes for Google accounts must be done through Google.',
          ),
        ),
      );
    } else {
      _showChangePasswordDialog(context);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();
    
    // Add state variables to track password visibility
    bool _isCurrentPasswordVisible = false;
    bool _isNewPasswordVisible = false;
    bool _isConfirmPasswordVisible = false;
    
    // Create a form key for validation
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(28, 28, 30, 1.0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDF4D0F), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Current Password Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDF4D0F)),
                          ),
                          child: TextFormField(
                            controller: currentPasswordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: !_isCurrentPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Current Password',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Text(
                                  'Required',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New Password Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDF4D0F)),
                          ),
                          child: TextFormField(
                            controller: newPasswordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: !_isNewPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'New Password',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordVisible = !_isNewPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Text(
                                  'Password is required',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (value.length < 8) {

                                return Text(
                                  'Must be at least 8 characters',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return Text(
                                  'Must contain uppercase',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return Text(
                                  'Must contain lowercase',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return Text(
                                  'Must contain number',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                                  .hasMatch(value)) {
                                return Text(
                                  'Must contain special character',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDF4D0F)),
                          ),
                          child: TextFormField(
                            controller: confirmNewPasswordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Text(
                                  'Required',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              } else if (value != newPasswordController.text) {
                                return Text(
                                  'Passwords don\'t match',
                                  style: TextStyle(fontSize: 5.0, color: Colors.red),
                                ).data;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(60, 60, 62, 1.0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        color: Color(0xFFDF4D0F),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  // Validate the form
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  
                                  final currentPassword = currentPasswordController.text.trim();
                                  final newPassword = newPasswordController.text.trim();
                                  final confirmNewPassword = confirmNewPasswordController.text.trim();

                                  try {
                                    // Re-authenticate the user
                                    final user = FirebaseAuth.instance.currentUser;
                                    final cred = EmailAuthProvider.credential(
                                        email: user!.email!, password: currentPassword);

                                    await user.reauthenticateWithCredential(cred);

                                    // Update the password
                                    await user.updatePassword(newPassword);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password changed successfully.'),
                                      ),
                                    );
                                  } catch (e) {
                                    print('Error changing password: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to change password: $e'),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDF4D0F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'SAVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(223, 77, 15, 1.0)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  
                  // Close the dialog
                  Navigator.pop(context);
                  
                  // Navigate to login page and clear all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    CustomPageRoute(
                      child: const FirstLoginCheck(),
                      transitionType: TransitionType.fade,
                    ),
                    (route) => false, // This predicate ensures all previous routes are removed
                  );
                } catch (e) {
                  print('Error signing out: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
              ),
              child: const Text('Log Out',
              style: TextStyle(color:Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
