import 'package:flutter/material.dart';
import '../models/diet_plan.dart';
import '../services/diet_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'diet_recommendations_page.dart';

class SelectedDietPage extends StatefulWidget {
  final DietPlan dietPlan;

  const SelectedDietPage({
    super.key,
    required this.dietPlan,
  });

  @override
  State<SelectedDietPage> createState() => _SelectedDietPageState();
}

class _SelectedDietPageState extends State<SelectedDietPage> {
  final DietService _dietService = DietService();

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
          'Summary',
          style: TextStyle(
            color: Color(0xFFDF4D0F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                 
                  Text(
                    '${widget.dietPlan.name.toUpperCase()} DIET',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFDF4D0F),
                            size: 50,
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
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFDF4D0F),
                            size: 50,
                          ),
                        );
                      },
                    ),
              ),
            ),

            // Change Diet Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to diet recommendations to change diet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DietRecommendationsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF4D0F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Change Diet',
                    style: TextStyle(
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
                      'Key features to follow',
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