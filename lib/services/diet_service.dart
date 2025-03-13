import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diet_plan.dart';
import '../models/user_model.dart';

class DietService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get diet recommendations based on user's BMI and fitness goal
  Future<List<DietPlan>> getDietRecommendations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
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

      // For now, return mock data based on user's BMI and goal
      // In a real app, you would fetch this from Firestore
      return _getMockDietPlans(userModel);
    } catch (e) {
      print('Error getting diet recommendations: $e');
      rethrow;
    }
  }

  // Save user's selected diet plan
  Future<void> saveSelectedDietPlan(String dietPlanId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'selectedDietPlan': dietPlanId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving selected diet plan: $e');
      rethrow;
    }
  }

  // Get user's selected diet plan
  Future<String?> getSelectedDietPlan() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['selectedDietPlan'] as String?;
    } catch (e) {
      print('Error getting selected diet plan: $e');
      return null;
    }
  }

  // Mock data for diet plans
  List<DietPlan> _getMockDietPlans(UserModel user) {
    final List<DietPlan> dietPlans = [];
    
    // Calculate BMI if possible
    double? bmi = user.bmi;
    String? goal = user.goal;
    
    // Low-Carb Diet
    dietPlans.add(DietPlan(
      id: 'low-carb',
      name: 'Low-Carbs',
      description: 'Lose weight a little faster by limiting calories coming from carbs. In turn, safely lower your blood sugar, improve your insulin sensitivity, get quality proteins and fats to feel fuller longer with sustained energy and in super-short terms, avoid energy crashes.',
      imageUrl: 'assets/Fitscale_LOGO.png', // Using existing logo as placeholder
      benefits: [
        'Protein-rich meals keep you filled and fueled',
        'Helps lower blood sugar and improve insulin',
        'Allows more vegetables and less starchy foods',
        'Good for short-term weight loss',
      ],
      foodGroups: [
        'Meat', 'Fish', 'Eggs', 'Vegetables', 'Nuts', 'Healthy oils', 'Limited fruits', 'Limited whole grains'
      ],
      mealPlan: {
        'breakfast': ['Eggs with avocado and spinach', 'Greek yogurt with berries and nuts'],
        'lunch': ['Grilled chicken salad with olive oil dressing', 'Tuna salad with mixed greens'],
        'dinner': ['Steak with roasted vegetables', 'Salmon with asparagus and butter'],
        'snacks': ['Almonds and cheese', 'Celery with almond butter', 'Hard-boiled eggs']
      },
      caloriesPerDay: 1800,
      suitableFor: ['Weight loss', 'Diabetes management', 'Metabolic health'],
    ));
    
    // Low-Fat Diet
    dietPlans.add(DietPlan(
      id: 'low-fat',
      name: 'Low-Fat',
      description: 'Focus on reducing overall fat intake while emphasizing complex carbohydrates. This approach helps manage cholesterol levels and supports heart health while providing steady energy throughout the day.',
      imageUrl: 'assets/Fitscale_LOGO.png', // Using existing logo as placeholder
      benefits: [
        'Supports heart health and cholesterol management',
        'Provides steady energy from complex carbs',
        'Rich in fiber and essential nutrients',
        'May reduce risk of certain cancers',
      ],
      foodGroups: [
        'Whole grains', 'Fruits', 'Vegetables', 'Lean proteins', 'Low-fat dairy', 'Legumes'
      ],
      mealPlan: {
        'breakfast': ['Oatmeal with fruit and a drizzle of honey', 'Whole grain toast with jam and fruit'],
        'lunch': ['Grilled chicken breast with brown rice and vegetables', 'Vegetable soup with whole grain bread'],
        'dinner': ['Baked fish with sweet potatoes and steamed vegetables', 'Pasta primavera with lean protein'],
        'snacks': ['Fresh fruit', 'Rice cakes with hummus', 'Fat-free yogurt with berries']
      },
      caloriesPerDay: 1600,
      suitableFor: ['Heart health', 'Weight management', 'Gallbladder issues'],
    ));
    
    // Vegetarian Diet
    dietPlans.add(DietPlan(
      id: 'vegetarian',
      name: 'Vegetarian',
      description: 'A plant-based approach that eliminates meat while focusing on nutrient-dense foods like vegetables, fruits, whole grains, and plant proteins. This diet supports overall health while reducing environmental impact.',
      imageUrl: 'assets/Fitscale_LOGO.png', // Using existing logo as placeholder
      benefits: [
        'Rich in fiber, vitamins, and antioxidants',
        'Supports heart health and reduces inflammation',
        'Lower environmental impact than meat-based diets',
        'Versatile and adaptable to different tastes',
      ],
      foodGroups: [
        'Fruits', 'Vegetables', 'Whole grains', 'Legumes', 'Nuts', 'Seeds', 'Dairy (optional)', 'Eggs (optional)'
      ],
      mealPlan: {
        'breakfast': ['Smoothie with plant protein, fruits, and spinach', 'Avocado toast with eggs or tofu scramble'],
        'lunch': ['Quinoa bowl with roasted vegetables and chickpeas', 'Lentil soup with whole grain bread'],
        'dinner': ['Bean and vegetable stir-fry with brown rice', 'Vegetable curry with tofu and quinoa'],
        'snacks': ['Hummus with vegetable sticks', 'Trail mix with nuts and dried fruit', 'Greek yogurt with honey']
      },
      caloriesPerDay: 1700,
      suitableFor: ['Ethical concerns', 'Environmental concerns', 'Health improvement', 'Heart health'],
    ));
    
    // High-Protein Diet
    dietPlans.add(DietPlan(
      id: 'high-protein',
      name: 'High-Protein',
      description: 'Maximize muscle growth and recovery by prioritizing protein intake. This approach supports athletic performance, enhances metabolism, and helps maintain lean muscle mass during weight loss.',
      imageUrl: 'assets/Fitscale_LOGO.png', // Using existing logo as placeholder
      benefits: [
        'Supports muscle growth and recovery',
        'Increases satiety and reduces hunger',
        'Boosts metabolism and fat burning',
        'Preserves lean muscle during weight loss',
      ],
      foodGroups: [
        'Lean meats', 'Fish', 'Eggs', 'Dairy', 'Legumes', 'Protein supplements', 'Nuts and seeds', 'Whole grains'
      ],
      mealPlan: {
        'breakfast': ['Protein shake with banana and almond butter', 'Egg white omelet with vegetables and turkey'],
        'lunch': ['Grilled chicken breast with quinoa and vegetables', 'Tuna salad with beans and mixed greens'],
        'dinner': ['Lean steak with sweet potatoes and broccoli', 'Turkey meatballs with zucchini noodles'],
        'snacks': ['Protein bar', 'Greek yogurt with berries', 'Cottage cheese with fruit']
      },
      caloriesPerDay: 2000,
      suitableFor: ['Muscle building', 'Weight loss', 'Athletic performance', 'Recovery'],
    ));
    
    // Return all diet plans for now
    // In a real app, you would filter based on user's BMI and goals
    return dietPlans;
  }
} 