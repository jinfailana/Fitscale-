import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../navigation/custom_navbar.dart';
import '../utils/custom_page_route.dart';
import '../screens/recommendations_page.dart';
import '../HistoryPage/history.dart';
import '../models/user_model.dart';
import 'summary_page.dart';
import 'manage_acc.dart';

class MeasureWeightPage extends StatefulWidget {
  const MeasureWeightPage({super.key});

  @override
  _MeasureWeightPageState createState() => _MeasureWeightPageState();
}

class _MeasureWeightPageState extends State<MeasureWeightPage> {
  double weight = 0.0;
  bool isLoading = true;
  Map<String, dynamic>? weightHistoryData;
  static const platform = MethodChannel('com.fitscale.app/settings');
  int _selectedIndex = 0; // Set to 0 for Home tab since this is part of the summary section

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user's current weight
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          setState(() {
            weight = userDoc['weight'] != null 
                ? (userDoc['weight'] as num).toDouble() 
                : 0.0;
          });
        }
        
        // Fetch weight history (most recent entry)
        final historyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weightHistory')
            .orderBy('date', descending: true)
            .limit(1)
            .get();
            
        if (historyDoc.docs.isNotEmpty) {
          final data = historyDoc.docs.first.data();
          setState(() {
            weightHistoryData = {
              'weight': data['weight'] ?? 0.0,
              'date': data['date'] != null 
                  ? (data['date'] as Timestamp).toDate() 
                  : DateTime.now(),
            };
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveWeight() async {
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update user's current weight
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'weight': weight});
            
        // Add to weight history
        final now = DateTime.now();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weightHistory')
            .add({
              'weight': weight,
              'date': Timestamp.fromDate(now),
            });
            
        setState(() {
          weightHistoryData = {
            'weight': weight,
            'date': now,
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight saved successfully'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          ),
        );
      }
    } catch (e) {
      print('Error saving weight: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save weight'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWeightInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double inputWeight = weight;
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(45, 45, 45, 1.0),
          title: const Text(
            'Enter Weight',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0)),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                inputWeight = double.tryParse(value) ?? weight;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  weight = inputWeight;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color.fromRGBO(223, 77, 15, 1.0)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Simplified method to show instructions and handle Bluetooth settings
  void _connectToScale() {
    // First show instructions
    _showManualInstructions();
  }

  // Show a dialog with instructions for manually connecting
  void _showManualInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        title: const Text(
          'Connect to Smart Scale',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To connect to your smart scale:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '1. Open your device settings',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '2. Go to Bluetooth settings',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '3. Make sure Bluetooth is turned on',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '4. Put your scale in pairing mode',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '5. Select the scale from the list of available devices',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openBluetoothSettings();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
            ),
            child: const Text(
              'Open Bluetooth Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to open Bluetooth settings
  Future<void> _openBluetoothSettings() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Bluetooth settings...'),
          backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
          duration: Duration(seconds: 2),
        ),
      );
      
      if (Platform.isAndroid) {
        // Try multiple approaches for Android
        try {
          // First try the platform channel
          await platform.invokeMethod('openBluetoothSettings');
        } catch (e) {
          print('Platform channel failed: $e');
          // If that fails, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check that your MainActivity.kt file is set up correctly'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else if (Platform.isIOS) {
        // iOS doesn't allow direct opening of settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('On iOS, please go to Settings > Bluetooth manually'),
            backgroundColor: Color.fromRGBO(223, 77, 15, 1.0),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error opening Bluetooth settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Bluetooth settings. Please go to Settings > Bluetooth manually.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const SummaryPage(),
          transitionType: TransitionType.leftToRight,
        ),
      );
    } else if (index == 1) {
      // Navigate to RecommendationsPage through the loadAndNavigateToRecommendations function
      _loadAndNavigateToRecommendations();
    } else if (index == 2) {
      // Navigate to HistoryPage
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: const HistoryPage(),
          transitionType: TransitionType.rightToLeft,
        ),
      );
    } else if (index == 3) {
      // Show profile modal
      _showProfileModal(context);
    }
  }

  void _showProfileModal(BuildContext context) {
    // Fetch user data from Firestore
    final user = FirebaseAuth.instance.currentUser;
    String username = 'User';
    String email = user?.email ?? '';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch user data if available
            if (user != null) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get()
                  .then((doc) {
                if (doc.exists) {
                  setState(() {
                    username = doc['username'] ?? 'User';
                    email = user.email ?? '';
                  });
                }
              }).catchError((e) {
                print('Error fetching user data: $e');
              });
            }
            
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(28, 28, 30, 1.0),
                borderRadius: BorderRadius.only(
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
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Color(0xFFDF4D0F),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // User profile card
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Close the modal first
                        Navigator.push(
                          context,
                          CustomPageRoute(child: const ManageAccPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(28, 28, 30, 1.0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDF4D0F)),
                        ),
                        child: Row(
                          children: [
                            // Profile picture
                            const CircleAvatar(
                              backgroundColor: Color.fromRGBO(223, 77, 15, 0.2),
                              radius: 20,
                              child: Icon(
                                Icons.person,
                                color: Color(0xFFDF4D0F),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // My Device option
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // Handle device settings
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(28, 28, 30, 1.0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDF4D0F)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.devices,
                              color: Color(0xFFDF4D0F),
                              size: 24,
                            ),
                            SizedBox(width: 16),
                            Text(
                              'My Device',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
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

      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: RecommendationsPage(user: userModel),
          transitionType: TransitionType.rightToLeft,
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
      backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDF4D0F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Summary',
          style: TextStyle(
            color: Color(0xFFDF4D0F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(223, 77, 15, 1.0),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'See your changes',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 300,
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(28, 28, 30, 1.0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color.fromRGBO(223, 77, 15, 1.0), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${weight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 50 * 0.9,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(223, 77, 15, 1.0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.monitor_weight,
                            color: Color.fromRGBO(223, 77, 15, 1.0),
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _connectToScale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Connect to Smart Scale',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: saveWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(45, 45, 45, 1.0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Weight',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Weight History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(28, 28, 30, 1.0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color.fromRGBO(223, 77, 15, 1.0), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Table(
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0), width: 1),
                          verticalInside: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0), width: 1),
                        ),
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color.fromRGBO(223, 77, 15, 0.1)),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    'Weight',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    'Date',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Display weight history or placeholder
                          weightHistoryData != null
                              ? TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          '${weightHistoryData!['weight'].toStringAsFixed(1)} kg',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          DateFormat('MMM d, yyyy').format(weightHistoryData!['date']),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          'No weight history available.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('', style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}