import 'package:flutter/material.dart';
import '../models/diet_plan.dart';
import '../services/diet_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DietDetailsPage extends StatefulWidget {
  final DietPlan dietPlan;
  final bool isSelected;
  final VoidCallback onSelect;

  const DietDetailsPage({
    super.key, 
    required this.dietPlan, 
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  State<DietDetailsPage> createState() => _DietDetailsPageState();
}

class _DietDetailsPageState extends State<DietDetailsPage> {
  final DietService _dietService = DietService();
  bool _isSelected = false;
  bool _isLoading = false;
  Stream<String?>? _selectedDietPlanStream;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
    _selectedDietPlanStream = _dietService.selectedDietPlanStream();
  }

  Future<void> _selectDietPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save to Firestore history
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('diet_history')
            .add({
          'dietPlanId': widget.dietPlan.id,
          'dietPlanName': widget.dietPlan.name,
          'date': now,
          'caloriesPerDay': widget.dietPlan.caloriesPerDay,
          'mealPlan': widget.dietPlan.mealPlan,
          'description': widget.dietPlan.description,
          'benefits': widget.dietPlan.benefits,
          'foodGroups': widget.dietPlan.foodGroups,
          'suitableFor': widget.dietPlan.suitableFor,
        });

        // Also update the user's current diet plan
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'currentDietPlan': {
            'id': widget.dietPlan.id,
            'name': widget.dietPlan.name,
            'caloriesPerDay': widget.dietPlan.caloriesPerDay,
            'selectedDate': now,
          }
        });
      }

      widget.onSelect();
      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diet plan selected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error selecting diet plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select diet plan: $e'),
          backgroundColor: Colors.red,
        ),
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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFDF4D0F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nutrition',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFDF4D0F)),
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ],
      ),
      body: StreamBuilder<String?>(
        stream: _selectedDietPlanStream,
        initialData: widget.isSelected ? widget.dietPlan.id : null,
        builder: (context, snapshot) {
          final selectedDietPlanId = snapshot.data;
          final isSelected = selectedDietPlanId == widget.dietPlan.id;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Color(0xFFDF4D0F),
                      ),
                      Text(
                        '${widget.dietPlan.name.toUpperCase()} DIET',
                        style: const TextStyle(
                          color: Color(0xFFDF4D0F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected) 
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Selected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Large diet image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDF4D0F).withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.dietPlan.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.dietPlan.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFFDF4D0F),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Loading diet image...",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading diet image: $error');
                            return Container(
                              color: Colors.grey.shade800,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFFDF4D0F),
                                    size: 50,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${widget.dietPlan.name} Diet",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          widget.dietPlan.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade800,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFFDF4D0F),
                                    size: 50,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${widget.dietPlan.name} Diet",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ),

                // Select Diet Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSelected || _isLoading ? null : _selectDietPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.green : const Color(0xFFDF4D0F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: isSelected ? Colors.green.withOpacity(0.7) : Colors.grey,
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
                          : Text(
                              isSelected ? 'SELECTED' : 'Select Diet',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                
                // Motivational text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Pump up protein and cut back on carbs to get faster results.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // How it Works section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How it Works',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.dietPlan.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Highlights section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Highlights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.dietPlan.benefits.map((benefit) => 
                        _buildHighlightItem(benefit)
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Key features section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Create FatSecret search URL based on diet type
                        String dietType = widget.dietPlan.name.toLowerCase().replaceAll('-', ' ');
                        String searchQuery = Uri.encodeComponent('$dietType diet plan');
                        final Uri url = Uri.parse('https://www.fatsecret.com/calories-nutrition/search?q=$searchQuery');
                        
                        if (!await canLaunchUrl(url)) {
                          throw Exception('Could not launch $url');
                        }
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not open FatSecret website: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      side: const BorderSide(color: Color(0xFFDF4D0F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Key features to follows',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new,
                          color: Color(0xFFDF4D0F),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Calories per day
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildInfoSection(
                    'Calories per Day',
                    '${widget.dietPlan.caloriesPerDay} kcal',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Food Groups
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildListSection('Food Groups', widget.dietPlan.foodGroups),
                ),
                
                const SizedBox(height: 24),
                
                // Meal Plan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildMealPlanSection(),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDF4D0F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFDF4D0F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFFDF4D0F),
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMealPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sample Meal Plan',
          style: TextStyle(
            color: Color(0xFFDF4D0F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Breakfast
        _buildMealTimeSection('Breakfast', widget.dietPlan.mealPlan['breakfast'] ?? []),
        const SizedBox(height: 16),
        
        // Lunch
        _buildMealTimeSection('Lunch', widget.dietPlan.mealPlan['lunch'] ?? []),
        const SizedBox(height: 16),
        
        // Dinner
        _buildMealTimeSection('Dinner', widget.dietPlan.mealPlan['dinner'] ?? []),
        const SizedBox(height: 16),
        
        // Snacks
        _buildMealTimeSection('Snacks', widget.dietPlan.mealPlan['snacks'] ?? []),
      ],
    );
  }

  Widget _buildMealTimeSection(String mealTime, List<String> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDF4D0F).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            mealTime,
            style: const TextStyle(
              color: Color(0xFFDF4D0F),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...meals.map((meal) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
} 