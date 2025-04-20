import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diet_plan.dart';
import '../services/diet_service.dart';
import '../utils/custom_page_route.dart';
import '../navigation/custom_navbar.dart';
import 'diet_details_page.dart';

class DietRecommendationsPage extends StatefulWidget {
  const DietRecommendationsPage({super.key});

  @override
  State<DietRecommendationsPage> createState() => _DietRecommendationsPageState();
}

class _DietRecommendationsPageState extends State<DietRecommendationsPage> {
  final DietService _dietService = DietService();
  List<DietPlan> _dietPlans = [];
  String? _selectedDietPlanId;
  bool _isLoading = true;
  bool _isApiError = false;
  int _selectedIndex = 0;
  Stream<String?>? _selectedDietPlanStream;

  @override
  void initState() {
    super.initState();
    _loadDietRecommendations();
    _selectedDietPlanStream = _dietService.selectedDietPlanStream();
  }

  Future<void> _loadDietRecommendations() async {
    try {
      setState(() => _isLoading = true);
      
      // Get diet recommendations directly without API distinction
      final dietPlans = await _dietService.getDietRecommendations();
      final selectedDietPlanId = await _dietService.getSelectedDietPlan();
      
      if (dietPlans.isNotEmpty) {
        setState(() {
          _dietPlans = dietPlans;
          _selectedDietPlanId = selectedDietPlanId;
          _isLoading = false;
          _isApiError = false;
        });
      } else {
        throw Exception('No diet plans returned');
      }
    } catch (e) {
      print('Error loading diet recommendations: $e');
      setState(() {
        _isApiError = true;
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
      const loadingSnackBar = SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              )
            ),
            SizedBox(width: 16),
            Text('Saving your diet choice...'),
          ],
        ),
        duration: Duration(seconds: 1),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
      
      await _dietService.saveSelectedDietPlan(dietPlanId);
      
      // We don't need to update the UI here as the stream will handle it
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
          'Summary',
          style: TextStyle(
            color: Color(0xFFDF4D0F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isApiError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFDF4D0F)),
              onPressed: _loadDietRecommendations,
              tooltip: 'Retry API',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDF4D0F)))
          : StreamBuilder<String?>(
              stream: _selectedDietPlanStream,
              initialData: _selectedDietPlanId,
              builder: (context, snapshot) {
                final selectedDietPlanId = snapshot.data;
                
                return SingleChildScrollView(
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
                              ..._dietPlans.map((dietPlan) => _buildDietOption(
                                  dietPlan, 
                                  isSelected: dietPlan.id == selectedDietPlanId,
                                  onSelect: () => _selectDietPlan(dietPlan.id),
                              )),
                              
                              // We don't need separate "Selected Diet" section since we now 
                              // highlight the selected diet in the main list
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDietOption(
    DietPlan dietPlan, {
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to diet details page
        Navigator.push(
          context,
          CustomPageRoute(
            child: DietDetailsPage(
              dietPlan: dietPlan,
              onSelect: onSelect,
              isSelected: isSelected,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : const Color(0xFFDF4D0F),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
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
                        Row(
                          children: [
                            Text(
                              dietPlan.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                        const SizedBox(height: 4),
                        const Row(
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
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? Colors.green.withOpacity(0.5) : Colors.grey.shade700,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: dietPlan.imageUrl.startsWith('http')
                            ? Image.network(
                                dietPlan.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: const Color(0xFFDF4D0F),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Color(0xFFDF4D0F),
                                      size: 24,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
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
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
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