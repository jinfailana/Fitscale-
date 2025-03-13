import 'package:flutter/material.dart';
import '../models/diet_plan.dart';
import '../services/diet_service.dart';

class DietDetailsPage extends StatefulWidget {
  final DietPlan dietPlan;

  const DietDetailsPage({Key? key, required this.dietPlan}) : super(key: key);

  @override
  State<DietDetailsPage> createState() => _DietDetailsPageState();
}

class _DietDetailsPageState extends State<DietDetailsPage> {
  final DietService _dietService = DietService();
  bool _isSelected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfSelected();
  }

  Future<void> _checkIfSelected() async {
    try {
      final selectedDietPlanId = await _dietService.getSelectedDietPlan();
      setState(() {
        _isSelected = selectedDietPlanId == widget.dietPlan.id;
      });
    } catch (e) {
      print('Error checking if diet plan is selected: $e');
    }
  }

  Future<void> _selectDietPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dietService.saveSelectedDietPlan(widget.dietPlan.id);
      setState(() {
        _isSelected = true;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet plan selected successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error selecting diet plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select diet plan: $e')),
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
        title: Row(
          children: [
            Text(
              'Nutrition',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.share, color: Color(0xFFDF4D0F)),
              onPressed: () {
                // Share functionality would go here
              },
            ),
          ],
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
                  Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: Color(0xFFDF4D0F),
                  ),
                  Text(
                    '${widget.dietPlan.name.toUpperCase()} DIET',
                    style: TextStyle(
                      color: Color(0xFFDF4D0F),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Diet image with border
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFDF4D0F), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.dietPlan.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade800,
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          color: Color(0xFFDF4D0F),
                          size: 80,
                        ),
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
                  onPressed: _isSelected || _isLoading ? null : _selectDietPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSelected ? Colors.grey : const Color(0xFFDF4D0F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          _isSelected ? 'SELECTED' : 'Select Diet',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  Text(
                    'How it Works',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lose weight a little faster by limiting calories coming from carbs. In turn, safely lower your blood sugar, improve your insulin sensitivity, get quality proteins and fats to feel fuller longer with sustained energy and in super-short terms, avoid energy crashes.',
                    style: TextStyle(
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
                  Text(
                    'Highlights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHighlightItem('Protein-rich meals keep you filled and fueled'),
                  _buildHighlightItem('Helps lower blood sugar and improve insulin'),
                  _buildHighlightItem('Allows more vegetables and less starchy foods'),
                  _buildHighlightItem('Good for short-term weight loss'),
                ],
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
            margin: EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
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