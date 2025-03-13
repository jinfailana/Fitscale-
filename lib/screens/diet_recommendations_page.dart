import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diet_plan.dart';
import '../services/diet_service.dart';
import '../utils/custom_page_route.dart';
import '../navigation/custom_navbar.dart';
import 'diet_details_page.dart';

class DietRecommendationsPage extends StatefulWidget {
  const DietRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<DietRecommendationsPage> createState() => _DietRecommendationsPageState();
}

class _DietRecommendationsPageState extends State<DietRecommendationsPage> {
  final DietService _dietService = DietService();
  List<DietPlan> _dietPlans = [];
  String? _selectedDietPlanId;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDietRecommendations();
  }

  Future<void> _loadDietRecommendations() async {
    try {
      final dietPlans = await _dietService.getDietRecommendations();
      final selectedDietPlanId = await _dietService.getSelectedDietPlan();
      
      setState(() {
        _dietPlans = dietPlans;
        _selectedDietPlanId = selectedDietPlanId;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading diet recommendations: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load diet recommendations: $e')),
      );
    }
  }

  Future<void> _selectDietPlan(String dietPlanId) async {
    try {
      await _dietService.saveSelectedDietPlan(dietPlanId);
      setState(() {
        _selectedDietPlanId = dietPlanId;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet plan selected successfully')),
      );
    } catch (e) {
      print('Error selecting diet plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select diet plan: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index != _selectedIndex) {
      Navigator.pop(context);
    }
  }

  void _showProfileModal(BuildContext context) {
    // Implement profile modal if needed
  }

  Future<void> _loadAndNavigateToRecommendations() async {
    // Implement if needed
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
          'Nutrition Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDF4D0F)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(40, 40, 42, 1.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                size: 16,
                                color: Color(0xFFDF4D0F),
                              ),
                              Text(
                                'Summary',
                                style: TextStyle(
                                  color: Color(0xFFDF4D0F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Diet Recommendations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recommendations are based on your goal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Diet recommendations
                          ..._dietPlans.map((dietPlan) => _buildDietOption(dietPlan)),
                          
                          const SizedBox(height: 24),
                          
                          // Selected Diet section
                          if (_selectedDietPlanId != null) ...[
                            const Text(
                              'Selected Diet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSelectedDietPlan(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
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

  Widget _buildDietOption(DietPlan dietPlan) {
    return GestureDetector(
      onTap: () {
        // Navigate to diet details page
        Navigator.push(
          context,
          CustomPageRoute(
            child: DietDetailsPage(dietPlan: dietPlan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Diet name and view button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dietPlan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'View Diet',
                              style: TextStyle(
                                color: Color(0xFFDF4D0F),
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFFDF4D0F),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Diet image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      dietPlan.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFDF4D0F),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDietPlan() {
    final selectedDietPlan = _dietPlans.firstWhere(
      (plan) => plan.id == _selectedDietPlanId,
      orElse: () => _dietPlans.first,
    );

    return GestureDetector(
      onTap: () {
        // Navigate to diet details page
        Navigator.push(
          context,
          CustomPageRoute(
            child: DietDetailsPage(dietPlan: selectedDietPlan),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDF4D0F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Diet name and view button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDietPlan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Diet image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      selectedDietPlan.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFDF4D0F),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 