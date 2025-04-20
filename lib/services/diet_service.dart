import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/diet_plan.dart';
import '../models/user_model.dart';

class DietService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiBaseUrl = 'https://platform.fatsecret.com/rest/server.api'; // Updated to FatSecret API base URL
  
  // Remove Spoonacular API key
  // final String _spoonacularApiKey = "103a549104344571a45519d6ebd47304";
  
  // FatSecret API credentials
  final String _fatSecretClientId = "ecb2f72a93384829bcf9eca01a54d53d";
  final String _fatSecretClientSecret = "6ccf0d34a7c6443db9db8676e2712f36";
  String? _fatSecretAccessToken;
  DateTime? _tokenExpiryTime;

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

      // Try to fetch from FatSecret API
      try {
        final apiDiets = await getDietRecommendationsFromFatSecret(userModel);
        if (apiDiets.isNotEmpty) {
          return apiDiets;
        }
      } catch (e) {
        print('Error fetching diet recommendations from FatSecret API: $e');
        // If API fails, fall back to local recommendations
      }
      
      // Fallback to local recommendations
      return _getRecommendedDietPlans(userModel);
    } catch (e) {
      print('Error getting diet recommendations: $e');
      rethrow;
    }
  }

  // Get FatSecret API access token
  Future<String> _getFatSecretAccessToken() async {
    // Check if we have a valid token
    if (_fatSecretAccessToken != null && _tokenExpiryTime != null) {
      if (_tokenExpiryTime!.isAfter(DateTime.now())) {
        // Token is still valid
        return _fatSecretAccessToken!;
      }
    }
    
    // Get a new token
    try {
      final response = await http.post(
        Uri.parse('https://oauth.fatsecret.com/connect/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': _fatSecretClientId,
          'client_secret': _fatSecretClientSecret,
          'scope': 'basic premier',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _fatSecretAccessToken = data['access_token'];
        
        // Set token expiry time (usually 86400 seconds = 24 hours)
        int expiresIn = data['expires_in'] ?? 86400;
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: expiresIn - 300)); // 5 minutes buffer
        
        return _fatSecretAccessToken!;
      } else {
        throw Exception('Failed to get FatSecret access token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting FatSecret access token: $e');
      rethrow;
    }
  }

  // Fetch diet recommendations from FatSecret API
  Future<List<DietPlan>> getDietRecommendationsFromFatSecret(UserModel user) async {
    try {
      // Get access token for FatSecret API
      final accessToken = await _getFatSecretAccessToken();
      
      // Calculate BMI
      double? bmi = user.bmi;
      if (bmi == null || user.goal == null) {
        throw Exception('Cannot calculate BMI: missing or invalid data');
      }
      
      // Determine diet type based on BMI, weight, height, age and goal
      List<String> dietTypes = _getDietTypesForUser(bmi, user);
      
      // List to store all diet plans
      List<DietPlan> allDietPlans = [];
      
      // For each diet type, create a diet plan using FatSecret data
      for (String dietType in dietTypes) {
        try {
          // Search for foods that match the diet type from FatSecret
          final response = await http.post(
            Uri.parse(_apiBaseUrl),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'method': 'foods.search',
              'search_expression': '$dietType diet for ${_getAgeGroup(user.age ?? 30)}',
              'format': 'json',
              'max_results': '10',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            // Check if we got foods data
            if (data['foods'] != null && data['foods']['food'] != null) {
              // Get food items
              var foods = data['foods']['food'];
              if (foods is! List) {
                foods = [foods]; // Ensure it's a list
              }
              
              // Generate unique diet plan ID
              String dietPlanId = dietType.replaceAll(' ', '-').toLowerCase();
              
              // Format the diet name for display
              String dietName = dietType.split(' ').map((word) => 
                word[0].toUpperCase() + word.substring(1).toLowerCase()
              ).join('-');
              
              // Create meal plan categories
              Map<String, List<String>> mealPlan = {
                'breakfast': [],
                'lunch': [],
                'dinner': [],
                'snacks': []
              };
              
              // Use online images for diet plans
              String imageUrl = _fetchDietImage(dietType);
              
              // Add foods to meal plan
              for (var food in foods) {
                String foodName = food['food_name'] ?? '';
                
                if (foodName.isNotEmpty) {
                  // Get detailed nutrition info for the food
                  try {
                    final nutritionResponse = await http.post(
                      Uri.parse(_apiBaseUrl),
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                        'Content-Type': 'application/x-www-form-urlencoded',
                      },
                      body: {
                        'method': 'food.get',
                        'food_id': food['food_id'],
                        'format': 'json',
                      },
                    );
                    
                    if (nutritionResponse.statusCode == 200) {
                      final nutritionData = jsonDecode(nutritionResponse.body);
                      if (nutritionData['food'] != null) {
                        final calories = nutritionData['food']['servings']['serving'][0]['calories'] ?? '0';
                        final servingSize = nutritionData['food']['servings']['serving'][0]['serving_size'] ?? '';
                        
                        // Format the food name with calories
                        String formattedFoodName = '$foodName ($servingSize - $calories kcal)';
                        
                        // Assign foods to meal categories
                        if (mealPlan['breakfast']!.length < 2) {
                          mealPlan['breakfast']!.add(formattedFoodName);
                        } else if (mealPlan['lunch']!.length < 2) {
                          mealPlan['lunch']!.add(formattedFoodName);
                        } else if (mealPlan['dinner']!.length < 2) {
                          mealPlan['dinner']!.add(formattedFoodName);
                        } else if (mealPlan['snacks']!.isEmpty) {
                          mealPlan['snacks']!.add(formattedFoodName);
                        }
                      }
                    }
                  } catch (e) {
                    print('Error fetching nutrition info for $foodName: $e');
                    // If nutrition info fetch fails, just add the food name
                    if (mealPlan['breakfast']!.length < 2) {
                      mealPlan['breakfast']!.add(foodName);
                    } else if (mealPlan['lunch']!.length < 2) {
                      mealPlan['lunch']!.add(foodName);
                    } else if (mealPlan['dinner']!.length < 2) {
                      mealPlan['dinner']!.add(foodName);
                    } else if (mealPlan['snacks']!.isEmpty) {
                      mealPlan['snacks']!.add(foodName);
                    }
                  }
                }
              }
              
              // Ensure meal plans have some content
              _fillEmptyMealPlans(mealPlan, dietType);
              
              // Calculate personalized calorie needs based on user's data
              int caloriesPerDay = _calculatePersonalizedCalories(dietType, user);
              
              // Create a DietPlan object
              DietPlan dietPlan = DietPlan(
                id: dietPlanId,
                name: dietName,
                description: _getPersonalizedDietDescription(dietType, user),
                imageUrl: imageUrl,
                benefits: _getDietBenefits(dietType),
                foodGroups: _getDietFoodGroups(dietType),
                mealPlan: mealPlan,
                caloriesPerDay: caloriesPerDay,
                suitableFor: _getDietSuitability(dietType),
              );
              
              allDietPlans.add(dietPlan);
            }
          } else {
            print('FatSecret API error: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('Error fetching $dietType diet from FatSecret: $e');
        }
      }
      
      // If no diet plans were created, throw exception to try fallback
      if (allDietPlans.isEmpty) {
        throw Exception('No diet plans could be created from FatSecret API');
      }
      
      return allDietPlans;
    } catch (e) {
      print('Error in getDietRecommendationsFromFatSecret: $e');
      rethrow;
    }
  }
  
  // Get diet types based on user BMI and goal
  List<String> _getDietTypesForUser(double bmi, UserModel user) {
    List<String> dietTypes = [];
    final goalLower = user.goal?.toLowerCase() ?? '';
    final age = user.age ?? 30;
    final gender = user.gender?.toLowerCase() ?? 'male';
    
    // Add appropriate diet types based on BMI and goal
    if (bmi >= 25) { // Overweight
      if (goalLower.contains('weight loss') || goalLower.contains('lose')) {
        dietTypes.addAll(['low calorie', 'low carb', 'low fat']);
        
        // Add age-specific diets
        if (age > 40) {
          dietTypes.add('mediterranean');
        }
      } else {
        dietTypes.addAll(['balanced', 'low carb']);
      }
    } else if (bmi < 18.5) { // Underweight
      dietTypes.addAll(['high calorie', 'high protein']);
      
      // Gender-specific recommendations
      if (gender == 'male') {
        dietTypes.add('bulking');
      }
    } else { // Normal weight
      if (goalLower.contains('muscle') || goalLower.contains('strength') || goalLower.contains('build')) {
        dietTypes.addAll(['high protein', 'balanced']);
        if (gender == 'male') {
          dietTypes.add('bulking');
        }
      } else if (goalLower.contains('health') || goalLower.contains('maintain')) {
        dietTypes.addAll(['balanced', 'mediterranean']);
        
        // Age-specific additions
        if (age > 50) {
          dietTypes.add('dash');
        }
      } else {
        dietTypes.addAll(['balanced']);
      }
    }
    
    // Special diets based on user preference keywords
    if (goalLower.contains('vegan') || goalLower.contains('vegetarian') || 
        goalLower.contains('plant') || goalLower.contains('animal')) {
      if (goalLower.contains('vegan')) {
        dietTypes.add('vegan');
      } else {
        dietTypes.add('vegetarian');
      }
    }
    
    // Add intermittent fasting as an option for adults looking to lose weight
    if (age >= 18 && (goalLower.contains('weight loss') || goalLower.contains('lose'))) {
      dietTypes.add('intermittent-fasting');
    }
    
    // If no specific diet type determined, provide a default set
    if (dietTypes.isEmpty) {
      dietTypes = ['balanced', 'low carb', 'high protein', 'low fat'];
    }
    
    return dietTypes;
  }
  
  // Get age group string for API queries
  String _getAgeGroup(int age) {
    if (age < 18) return 'teen';
    if (age < 30) return 'young adult';
    if (age < 50) return 'adult';
    if (age < 65) return 'senior';
    return 'elderly';
  }
  
  // Generate a diet image based on user data and diet type
  Future<String?> _generateDietImage(String dietType, UserModel user) async {
    try {
      final diet = dietType.toLowerCase();
      
      // Create base image URLs based on diet types - using online images
      Map<String, String> dietImages = {
        'low carb': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
        'low fat': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'high protein': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'balanced': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
        'vegetarian': 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
        'vegan': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'mediterranean': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
        'keto': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'dash': 'https://images.unsplash.com/photo-1466637574441-749b8f19452f',
        'paleo': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'intermittent-fasting': 'https://images.unsplash.com/photo-1590507621108-433608c97823',
        'high calorie': 'https://images.unsplash.com/photo-1504940892017-d23b9053d5d4',
        'low calorie': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'bulking': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
      };
      
      // Return diet-specific image
      if (dietImages.containsKey(diet)) {
        return dietImages[diet];
      }
      
      // If no specific image found, return a default
      return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352';
    } catch (e) {
      print('Error generating diet image: $e');
      return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352';
    }
  }
  
  // Calculate personalized calories based on user data
  int _calculatePersonalizedCalories(String dietType, UserModel user) {
    // Base metabolic rate using Harris-Benedict equation
    double bmr = 0;
    String? gender = user.gender?.toLowerCase();
    double weight = user.weight ?? 70; // kg
    double height = user.height ?? 170; // cm
    int age = user.age ?? 30;
    
    // Calculate BMR based on gender
    if (gender == 'female') {
      bmr = 655 + (9.6 * weight) + (1.8 * height) - (4.7 * age);
    } else {
      bmr = 66 + (13.7 * weight) + (5 * height) - (6.8 * age);
    }
    
    // Activity level multiplier
    double activityMultiplier = 1.2; // Sedentary
    String? activityLevel = user.activityLevel?.toLowerCase();
    if (activityLevel != null) {
      if (activityLevel.contains('light')) {
        activityMultiplier = 1.375;
      } else if (activityLevel.contains('moderate')) {
        activityMultiplier = 1.55;
      } else if (activityLevel.contains('active') || activityLevel.contains('high')) {
        activityMultiplier = 1.725;
      } else if (activityLevel.contains('very')) {
        activityMultiplier = 1.9;
      }
    }
    
    // Calculate daily calorie needs
    double dailyCalories = bmr * activityMultiplier;
    
    // Adjust based on diet type
    switch (dietType.toLowerCase()) {
      case 'low carb':
      case 'low fat':
      case 'low calorie':
        return (dailyCalories - 500).round(); // For weight loss
      case 'high protein':
        return dailyCalories.round();
      case 'high calorie':
      case 'bulking':
        return (dailyCalories + 500).round(); // For weight gain
      case 'ketogenic':
      case 'keto':
        return (dailyCalories - 300).round();
      default:
        return dailyCalories.round();
    }
  }
  
  // Get personalized diet description based on user data
  String _getPersonalizedDietDescription(String dietType, UserModel user) {
    final goal = user.goal?.toLowerCase() ?? '';
    final bmi = user.bmi ?? 25;
    String baseDescription = _getDietDescription(dietType);
    
    // Add personalized sentence based on user goals and metrics
    String personalizedSentence = '';
    if (goal.contains('weight loss') || goal.contains('lose')) {
      if (bmi >= 25) {
        personalizedSentence = ' This approach is ideal for your goal of weight loss and can help you achieve a healthier BMI.';
      } else {
        personalizedSentence = ' While you have a healthy BMI, this plan can help you achieve your toning and fitness goals.';
      }
    } else if (goal.contains('muscle') || goal.contains('strength') || goal.contains('build')) {
      personalizedSentence = ' This plan supports your goal of building muscle and strength with adequate protein and nutrients.';
    } else if (goal.contains('health') || goal.contains('maintain')) {
      personalizedSentence = ' This balanced approach aligns with your goal of maintaining overall health and wellbeing.';
    }
    
    return baseDescription + personalizedSentence;
  }

  // Fetch a relevant image for the diet type - using online images instead of local assets
  String _fetchDietImage(String dietType) {
    try {
      // Map diet types to online image URLs
      Map<String, String> defaultImages = {
        'low carb': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
        'low fat': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'high protein': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'balanced': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
        'vegetarian': 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
        'vegan': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'mediterranean': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
        'keto': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'dash': 'https://images.unsplash.com/photo-1466637574441-749b8f19452f',
        'paleo': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
        'intermittent-fasting': 'https://images.unsplash.com/photo-1590507621108-433608c97823',
        'high calorie': 'https://images.unsplash.com/photo-1504940892017-d23b9053d5d4',
        'low calorie': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        'bulking': 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
      };
      
      // Return appropriate image URL
      return defaultImages[dietType.toLowerCase()] ?? 'https://images.unsplash.com/photo-1498837167922-ddd27525d352';
    } catch (e) {
      print('Error fetching diet image: $e');
      return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352';
    }
  }

  // Helper method to get diet description
  String _getDietDescription(String dietType) {
    switch (dietType.toLowerCase()) {
      case 'low carb':
        return 'Lose weight a little faster by limiting calories coming from carbs. In turn, safely lower your blood sugar, improve your insulin sensitivity, get quality proteins and fats to feel fuller longer with sustained energy.';
      case 'low fat':
        return 'Focus on reducing overall fat intake while emphasizing complex carbohydrates. This approach helps manage cholesterol levels and supports heart health while providing steady energy throughout the day.';
      case 'high protein':
        return 'Maximize muscle growth and recovery by prioritizing protein intake. This approach supports athletic performance, enhances metabolism, and helps maintain lean muscle mass during weight loss.';
      case 'balanced':
        return 'A well-rounded approach that includes all food groups in appropriate portions. This balanced diet provides essential nutrients while maintaining flexibility and sustainability.';
      case 'vegetarian':
        return 'A plant-based approach that eliminates meat while focusing on nutrient-dense foods like vegetables, fruits, whole grains, and plant proteins. This diet supports overall health while reducing environmental impact.';
      case 'vegan':
        return 'A strict plant-based diet that excludes all animal products. Focus on a wide variety of fruits, vegetables, grains, legumes, and plant-based proteins to ensure nutritional adequacy.';
      case 'whole 30':
        return 'A 30-day clean-eating program that eliminates sugar, alcohol, grains, legumes, soy, and dairy. This reset helps identify food sensitivities and promotes whole, unprocessed foods.';
      case 'paleo':
        return 'Based on foods presumed to be available to paleolithic humans, focusing on fruits, vegetables, lean meats, fish, nuts, and seeds while avoiding processed foods, grains, and dairy.';
      case 'ketogenic':
      case 'keto':
        return 'A high-fat, very low-carb diet that forces your body to burn fats rather than carbohydrates. This metabolic state of ketosis can lead to rapid weight loss and improved energy levels.';
      case 'high calorie':
        return 'A diet designed to increase caloric intake for weight gain, featuring nutrient-dense foods and larger portion sizes. Ideal for those who are underweight or looking to build muscle mass.';
      case 'low calorie':
        return 'A calorie-restricted approach to promote weight loss while still providing essential nutrients. Focus on nutrient-dense, low-calorie foods to maintain satiety and energy levels.';
      default:
        return 'A customized eating plan designed to optimize your health based on your specific needs and goals. This approach balances nutrients to support overall wellness.';
    }
  }

  // Helper method to get diet benefits
  List<String> _getDietBenefits(String dietType) {
    switch (dietType.toLowerCase()) {
      case 'low carb':
        return [
          'Rapid weight loss',
          'Improved blood sugar control',
          'Reduced hunger and cravings',
          'Enhanced energy levels'
        ];
      case 'low fat':
        return [
          'Heart health and cholesterol management',
          'Steady energy from complex carbs',
          'Weight management',
          'Reduced risk of certain health conditions'
        ];
      case 'high protein':
        return [
          'Enhanced muscle growth and recovery',
          'Increased satiety and reduced hunger',
          'Improved metabolism',
          'Preserved lean muscle during weight loss'
        ];
      case 'balanced':
        return [
          'Complete nutrition from varied food groups',
          'Sustainable long-term approach',
          'Flexible and adaptable',
          'Supports overall health and wellbeing'
        ];
      case 'vegetarian':
        return [
          'Reduced environmental impact',
          'Lower risk of heart disease',
          'Rich in fiber and antioxidants',
          'Ethical treatment of animals'
        ];
      case 'vegan':
        return [
          'Minimal environmental footprint',
          'Ethical approach to food consumption',
          'Higher intake of antioxidants',
          'May reduce risk of certain diseases'
        ];
      case 'whole 30':
        return [
          'Identification of food sensitivities',
          'Elimination of processed foods',
          'Reset of eating habits and cravings',
          'Focus on whole, nutrient-dense foods'
        ];
      case 'paleo':
        return [
          'Elimination of processed foods',
          'Focus on nutrient-dense whole foods',
          'May reduce inflammation',
          'Stable blood sugar levels'
        ];
      case 'ketogenic':
      case 'keto':
        return [
          'Rapid weight loss through fat burning',
          'Reduced hunger and cravings',
          'Potential cognitive benefits',
          'May benefit certain medical conditions'
        ];
      case 'high calorie':
        return [
          'Supports weight gain goals',
          'Provides energy for intense workouts',
          'Helps build muscle mass',
          'Supports recovery after exercise'
        ];
      case 'low calorie':
        return [
          'Promotes weight loss',
          'May extend lifespan',
          'Potential metabolic benefits',
          'Focus on nutrient density'
        ];
      default:
        return [
          'Customized to your specific needs',
          'Balanced nutrition',
          'Supports overall health goals',
          'Sustainable approach to eating'
        ];
    }
  }

  // Helper method to get diet food groups
  List<String> _getDietFoodGroups(String dietType) {
    switch (dietType.toLowerCase()) {
      case 'low carb':
        return ['Proteins', 'Healthy fats', 'Low-carb vegetables', 'Limited fruits', 'Nuts and seeds'];
      case 'low fat':
        return ['Whole grains', 'Lean proteins', 'Fruits', 'Vegetables', 'Low-fat dairy', 'Legumes'];
      case 'high protein':
        return ['Lean meats', 'Fish', 'Eggs', 'Dairy', 'Legumes', 'Nuts and seeds', 'Protein supplements'];
      case 'balanced':
        return ['Whole grains', 'Lean proteins', 'Fruits', 'Vegetables', 'Dairy', 'Healthy fats'];
      case 'vegetarian':
        return ['Fruits', 'Vegetables', 'Whole grains', 'Legumes', 'Nuts and seeds', 'Dairy', 'Eggs'];
      case 'vegan':
        return ['Fruits', 'Vegetables', 'Whole grains', 'Legumes', 'Nuts and seeds', 'Plant-based proteins'];
      case 'whole 30':
        return ['Meats', 'Seafood', 'Eggs', 'Vegetables', 'Fruits', 'Natural fats', 'Herbs and spices'];
      case 'paleo':
        return ['Meats', 'Fish and seafood', 'Fruits', 'Vegetables', 'Nuts and seeds', 'Healthy oils'];
      case 'ketogenic':
      case 'keto':
        return ['Fats', 'Proteins', 'Low-carb vegetables', 'Limited berries', 'Nuts and seeds'];
      case 'high calorie':
        return ['Proteins', 'Complex carbs', 'Healthy fats', 'Dairy', 'Calorie-dense foods'];
      case 'low calorie':
        return ['Lean proteins', 'Vegetables', 'Fruits', 'Whole grains', 'Low-fat dairy'];
      default:
        return ['Proteins', 'Carbohydrates', 'Fats', 'Fruits', 'Vegetables', 'Dairy'];
    }
  }

  // Helper method to get diet calories
  int _getDietCalories(String dietType, double bmi, String goal) {
    // Base calories based on weight status
    int baseCalories;
    if (bmi >= 30) { // Obese
      baseCalories = 1500;
    } else if (bmi >= 25) { // Overweight
      baseCalories = 1700;
    } else if (bmi < 18.5) { // Underweight
      baseCalories = 2500;
    } else { // Normal weight
      baseCalories = 2000;
    }
    
    // Adjust based on diet type
    switch (dietType.toLowerCase()) {
      case 'low carb':
      case 'low fat':
      case 'low calorie':
        return baseCalories - 200;
      case 'high protein':
        return baseCalories + 100;
      case 'high calorie':
        return baseCalories + 500;
      case 'ketogenic':
      case 'keto':
        return baseCalories - 100;
      default:
        return baseCalories;
    }
  }

  // Helper method to get diet suitability
  List<String> _getDietSuitability(String dietType) {
    switch (dietType.toLowerCase()) {
      case 'low carb':
        return ['Weight loss', 'Diabetes management', 'Metabolic health', 'Blood sugar control'];
      case 'low fat':
        return ['Heart health', 'Cholesterol management', 'Weight loss', 'Gallbladder issues'];
      case 'high protein':
        return ['Muscle building', 'Athletic performance', 'Recovery', 'Weight management'];
      case 'balanced':
        return ['General health', 'Weight maintenance', 'Families', 'Long-term wellness'];
      case 'vegetarian':
        return ['Environmental concerns', 'Ethical considerations', 'Heart health', 'Cancer prevention'];
      case 'vegan':
        return ['Ethical considerations', 'Environmental impact', 'Animal welfare', 'Certain health conditions'];
      case 'whole 30':
        return ['Food sensitivity identification', 'Habit reset', 'Inflammation reduction', 'Digestive health'];
      case 'paleo':
        return ['Whole food focus', 'Autoimmune conditions', 'Digestive issues', 'Blood sugar management'];
      case 'ketogenic':
      case 'keto':
        return ['Rapid weight loss', 'Epilepsy management', 'Metabolic health', 'Cognitive function'];
      case 'high calorie':
        return ['Weight gain', 'Muscle building', 'Recovery', 'Athletic performance'];
      case 'low calorie':
        return ['Weight loss', 'Longevity', 'Metabolic health', 'Disease prevention'];
      default:
        return ['General health', 'Wellness', 'Balanced nutrition', 'Sustainable lifestyle'];
    }
  }

  // Fetch diet recommendations from external API
  Future<List<DietPlan>> _fetchDietRecommendationsFromApi(UserModel user) async {
    try {
      // Calculate BMI for API request
      double? bmi = user.bmi;
      if (bmi == null || user.goal == null) {
        return [];
      }
      
      // Prepare API request parameters
      final Map<String, dynamic> requestBody = {
        'bmi': bmi,
        'goal': user.goal,
        'gender': user.gender,
        'age': user.age,
        'activityLevel': user.activityLevel,
      };
      
      // Make API request
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['diets'];
        return data.map((diet) => DietPlan.fromMap(diet)).toList();
      } else {
        throw Exception('Failed to load diet recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('API request failed: $e');
      return [];
    }
  }

  // Save user's selected diet plan
  Future<void> saveSelectedDietPlan(String dietPlanId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Save to API for analytics and personalization
      try {
        await http.post(
          Uri.parse('$_apiBaseUrl/user-selection'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': user.uid,
            'dietPlanId': dietPlanId,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        print('Failed to save diet selection to API: $e');
        // Continue even if API call fails
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
  
  // Stream to listen for real-time updates to the selected diet plan
  Stream<String?> selectedDietPlanStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    
    return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final userData = snapshot.data() as Map<String, dynamic>;
      return userData['selectedDietPlan'] as String?;
    });
  }

  // Get recommended diet plans based on user's BMI and fitness goal
  List<DietPlan> _getRecommendedDietPlans(UserModel user) {
    final List<DietPlan> allDietPlans = _getAllDietPlans();
    final List<DietPlan> recommendedDiets = [];
    
    // Calculate BMI if possible
    double? bmi = user.bmi;
    String? goal = user.goal?.toLowerCase();
    
    // If BMI or goal is missing, return all diets
    if (bmi == null || goal == null) {
      return allDietPlans;
    }
    
    // Determine weight category
    String weightCategory;
    if (bmi < 18.5) {
      weightCategory = 'underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      weightCategory = 'normal';
    } else if (bmi >= 25 && bmi < 30) {
      weightCategory = 'overweight';
    } else {
      weightCategory = 'obese';
    }
    
    // Recommend diets based on BMI and goal
    for (var diet in allDietPlans) {
      bool shouldRecommend = false;
      
      if (goal.contains('weight loss') || goal.contains('lose weight')) {
        if (weightCategory == 'overweight' || weightCategory == 'obese') {
          if (diet.id == 'low-carb' || diet.id == 'low-fat' || diet.id == 'keto' || diet.id == 'intermittent-fasting') {
            shouldRecommend = true;
          }
        } else if (weightCategory == 'normal') {
          if (diet.id == 'balanced' || diet.id == 'mediterranean' || diet.id == 'dash') {
            shouldRecommend = true;
          }
        }
      } else if (goal.contains('muscle') || goal.contains('strength') || goal.contains('bulk')) {
        if (diet.id == 'high-protein' || diet.id == 'bulking' || diet.id == 'paleo') {
          shouldRecommend = true;
        }
      } else if (goal.contains('health') || goal.contains('maintain')) {
        if (diet.id == 'mediterranean' || diet.id == 'balanced' || diet.id == 'dash' || diet.id == 'vegetarian') {
          shouldRecommend = true;
        }
      }
      
      // Special case for ethical/environmental concerns
      if (goal.contains('environment') || goal.contains('ethical') || goal.contains('animal')) {
        if (diet.id == 'vegetarian' || diet.id == 'vegan') {
          shouldRecommend = true;
        }
      }
      
      // Special case for specific health conditions
      if (goal.contains('diabetes') || goal.contains('blood sugar')) {
        if (diet.id == 'low-carb' || diet.id == 'keto' || diet.id == 'dash') {
          shouldRecommend = true;
        }
      }
      
      if (goal.contains('heart') || goal.contains('cholesterol')) {
        if (diet.id == 'mediterranean' || diet.id == 'dash' || diet.id == 'low-fat') {
          shouldRecommend = true;
        }
      }
      
      // Always include some options if nothing matches
      if (recommendedDiets.length < 3) {
        shouldRecommend = true;
      }
      
      if (shouldRecommend && !recommendedDiets.any((d) => d.id == diet.id)) {
        recommendedDiets.add(diet);
      }
    }
    
    // If still no recommendations (unlikely), return all diets
    if (recommendedDiets.isEmpty) {
      return allDietPlans;
    }
    
    return recommendedDiets;
  }

  // Get all available diet plans (fallback when API fails)
  List<DietPlan> _getAllDietPlans() {
    final List<DietPlan> dietPlans = [];
    
    // Low-Carb Diet
    dietPlans.add(DietPlan(
      id: 'low-carb',
      name: 'Low-Carbs',
      description: 'Lose weight a little faster by limiting calories coming from carbs. In turn, safely lower your blood sugar, improve your insulin sensitivity, get quality proteins and fats to feel fuller longer with sustained energy and in super-short terms, avoid energy crashes.',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
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
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
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
    
    // Mediterranean Diet
    dietPlans.add(DietPlan(
      id: 'mediterranean',
      name: 'Mediterranean',
      description: 'Based on the traditional foods of Mediterranean countries, this diet emphasizes plant foods, healthy fats, and moderate consumption of fish, poultry, and dairy. It\'s known for its heart health benefits.',
      imageUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
      benefits: [
        'Reduces risk of heart disease and stroke',
        'May prevent cognitive decline',
        'Anti-inflammatory benefits',
        'Rich in antioxidants and nutrients',
      ],
      foodGroups: [
        'Olive oil', 'Vegetables', 'Fruits', 'Whole grains', 'Beans', 'Nuts', 'Fish', 'Moderate wine'
      ],
      mealPlan: {
        'breakfast': ['Greek yogurt with honey and walnuts', 'Whole grain bread with olive oil and tomatoes'],
        'lunch': ['Mediterranean salad with feta and olives', 'Lentil soup with whole grain bread'],
        'dinner': ['Grilled fish with vegetables and olive oil', 'Vegetable paella with seafood'],
        'snacks': ['Handful of nuts', 'Fresh fruit', 'Hummus with vegetables']
      },
      caloriesPerDay: 1800,
      suitableFor: ['Heart health', 'Longevity', 'Overall wellness'],
    ));
    
    // Keto Diet (New addition)
    dietPlans.add(DietPlan(
      id: 'keto',
      name: 'Ketogenic',
      description: 'A high-fat, very low-carb diet that forces your body to burn fats rather than carbohydrates. By drastically reducing carb intake and replacing it with fat, your body enters a metabolic state called ketosis.',
      imageUrl: 'https://images.unsplash.com/photo-1607532941433-304659e8198a',
      benefits: [
        'Rapid weight loss through fat burning',
        'Reduced hunger and appetite',
        'May improve certain health markers',
        'Can help manage epilepsy and neurological conditions',
      ],
      foodGroups: [
        'Fatty meats', 'Fish', 'Eggs', 'High-fat dairy', 'Nuts and seeds', 'Healthy oils', 'Low-carb vegetables'
      ],
      mealPlan: {
        'breakfast': ['Bacon and eggs with avocado', 'Keto smoothie with coconut milk and almond butter'],
        'lunch': ['Spinach salad with grilled salmon and olive oil', 'Bunless burger with cheese and vegetables'],
        'dinner': ['Steak with buttered broccoli', 'Baked chicken with cauliflower mash'],
        'snacks': ['Cheese slices', 'Pepperoni', 'Macadamia nuts', 'Keto fat bombs']
      },
      caloriesPerDay: 1900,
      suitableFor: ['Significant weight loss', 'Diabetes management', 'Epilepsy', 'Metabolic syndrome'],
    ));
    
    // Paleo Diet (New addition)
    dietPlans.add(DietPlan(
      id: 'paleo',
      name: 'Paleo',
      description: 'Based on foods that were available to our ancestors during the Paleolithic era, focusing on whole foods like lean meats, fish, fruits, vegetables, nuts, and seeds, while avoiding processed foods, grains, and dairy.',
      imageUrl: 'https://assets.clevelandclinic.org/transform/ebbd8c0f-9709-4b1d-bd99-e3e3151f0e3a/Paleo-Diet-1301565375-770x533-1_jpg',
      benefits: [
        'Eliminates processed foods and additives',
        'Rich in lean proteins and healthy fats',
        'May reduce inflammation',
        'Supports stable blood sugar levels',
      ],
      foodGroups: [
        'Lean meats', 'Fish', 'Fruits', 'Vegetables', 'Nuts and seeds', 'Healthy oils'
      ],
      mealPlan: {
        'breakfast': ['Sweet potato hash with eggs and avocado', 'Fruit salad with nuts'],
        'lunch': ['Grilled chicken over mixed greens with olive oil dressing', 'Tuna wrapped in lettuce leaves'],
        'dinner': ['Grilled steak with roasted vegetables', 'Baked salmon with asparagus'],
        'snacks': ['Apple slices with almond butter', 'Beef jerky', 'Mixed berries', 'Trail mix']
      },
      caloriesPerDay: 1900,
      suitableFor: ['Weight loss', 'Autoimmune conditions', 'Digestive health', 'Athletic performance'],
    ));
    
    // DASH Diet (New addition)
    dietPlans.add(DietPlan(
      id: 'dash',
      name: 'DASH',
      description: 'Dietary Approaches to Stop Hypertension (DASH) is designed to prevent and lower high blood pressure. It emphasizes fruits, vegetables, whole grains, and lean proteins, while limiting sodium, red meat, and added sugars.',
      imageUrl: 'https://images.unsplash.com/photo-1466637574441-749b8f19452f',
      benefits: [
        'Reduces blood pressure and improves heart health',
        'Lowers risk of heart disease, stroke, and cancer',
        'Rich in nutrients that help bone health',
        'Sustainable long-term eating pattern',
      ],
      foodGroups: [
        'Fruits', 'Vegetables', 'Whole grains', 'Lean proteins', 'Low-fat dairy', 'Nuts and seeds', 'Limited sodium'
      ],
      mealPlan: {
        'breakfast': ['Whole grain cereal with low-fat milk and berries', 'Whole grain toast with fruit spread'],
        'lunch': ['Grilled chicken sandwich on whole grain bread with veggies', 'Vegetable soup with whole grain roll'],
        'dinner': ['Baked fish with brown rice and steamed vegetables', 'Turkey chili with mixed green salad'],
        'snacks': ['Fresh fruit', 'Yogurt', 'Unsalted nuts', 'Vegetable sticks with hummus']
      },
      caloriesPerDay: 1800,
      suitableFor: ['Hypertension', 'Heart disease prevention', 'Overall health', 'Diabetes management'],
    ));
    
    // Intermittent Fasting (New addition)
    dietPlans.add(DietPlan(
      id: 'intermittent-fasting',
      name: 'Intermittent Fasting',
      description: 'An eating pattern that cycles between periods of fasting and eating. It doesn\'t specify which foods to eat but rather when you should eat them. Common methods include the 16/8 method, the 5:2 diet, and the eat-stop-eat approach.',
      imageUrl: 'https://images.unsplash.com/photo-1590507621108-433608c97823',
      benefits: [
        'May help with weight loss and fat burning',
        'Can improve insulin sensitivity and blood sugar',
        'May enhance cellular repair processes',
        'Potential cognitive and longevity benefits',
      ],
      foodGroups: [
        'No specific food groups, focus on nutritious foods during eating windows'
      ],
      mealPlan: {
        'breakfast': ['Often skipped in 16/8 method', 'Light protein shake if needed'],
        'lunch': ['Large salad with protein and healthy fats', 'Substantial meal with balanced nutrients'],
        'dinner': ['Protein-rich meal with vegetables', 'Balanced meal with all macronutrients'],
        'snacks': ['Minimal snacking, focus on nutritious meals']
      },
      caloriesPerDay: 1800,
      suitableFor: ['Weight loss', 'Metabolic health', 'Simplicity seekers', 'Busy lifestyles'],
    ));
    
    // Vegetarian Diet
    dietPlans.add(DietPlan(
      id: 'vegetarian',
      name: 'Vegetarian',
      description: 'A plant-based approach that eliminates meat while focusing on nutrient-dense foods like vegetables, fruits, whole grains, and plant proteins. This diet supports overall health while reducing environmental impact.',
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
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
    
    // Vegan Diet (New addition)
    dietPlans.add(DietPlan(
      id: 'vegan',
      name: 'Vegan',
      description: 'A plant-based diet that excludes all animal products, including meat, dairy, eggs, and honey. Focuses on fruits, vegetables, grains, legumes, nuts, and seeds to provide all necessary nutrients.',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
      benefits: [
        'May lower risk of heart disease and certain cancers',
        'Often associated with lower BMI and weight loss',
        'Reduces environmental impact and animal suffering',
        'Rich in antioxidants and phytonutrients',
      ],
      foodGroups: [
        'Fruits', 'Vegetables', 'Whole grains', 'Legumes', 'Nuts', 'Seeds', 'Plant-based proteins'
      ],
      mealPlan: {
        'breakfast': ['Overnight oats with plant milk and fruits', 'Tofu scramble with vegetables'],
        'lunch': ['Buddha bowl with quinoa, roasted vegetables, and chickpeas', 'Lentil and vegetable soup'],
        'dinner': ['Bean and vegetable chili with brown rice', 'Pasta with vegetable marinara and plant-based protein'],
        'snacks': ['Hummus with vegetables', 'Energy balls with dates and nuts', 'Fruit with almond butter']
      },
      caloriesPerDay: 1600,
      suitableFor: ['Ethical concerns', 'Environmental impact', 'Heart health', 'Cancer prevention'],
    ));
    
    // High-Protein Diet
    dietPlans.add(DietPlan(
      id: 'high-protein',
      name: 'High-Protein',
      description: 'Maximize muscle growth and recovery by prioritizing protein intake. This approach supports athletic performance, enhances metabolism, and helps maintain lean muscle mass during weight loss.',
      imageUrl: 'https://domf5oio6qrcr.cloudfront.net/medialibrary/14727/conversions/28e8e464-f55e-4b32-9bab-dc990d8cc927-thumb.jpg',
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
    
    // Balanced Diet
    dietPlans.add(DietPlan(
      id: 'balanced',
      name: 'Balanced',
      description: 'A well-rounded approach that includes all food groups in appropriate portions. This balanced diet provides essential nutrients while maintaining flexibility and sustainability.',
      imageUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
      benefits: [
        'Provides complete nutrition',
        'Sustainable and flexible long-term',
        'Supports overall health and wellbeing',
        'Adaptable to different lifestyles',
      ],
      foodGroups: [
        'Whole grains', 'Proteins', 'Fruits', 'Vegetables', 'Dairy', 'Healthy fats'
      ],
      mealPlan: {
        'breakfast': ['Whole grain cereal with milk and fruit', 'Whole grain toast with eggs and avocado'],
        'lunch': ['Turkey sandwich on whole grain bread with vegetables', 'Mixed grain bowl with vegetables and protein'],
        'dinner': ['Grilled chicken with roasted vegetables and quinoa', 'Fish with sweet potato and green beans'],
        'snacks': ['Apple with peanut butter', 'Greek yogurt with berries', 'Hummus with vegetables']
      },
      caloriesPerDay: 1900,
      suitableFor: ['General health', 'Weight maintenance', 'Families', 'Beginner dieters'],
    ));
    
    // Bulking Diet
    dietPlans.add(DietPlan(
      id: 'bulking',
      name: 'Mass Gainer',
      description: 'A high-calorie diet designed for those looking to gain muscle mass. This approach provides surplus calories and protein to support muscle growth during intense training.',
      imageUrl: 'https://i.redd.it/861t9s6zb9w51.jpg',
      benefits: [
        'Supports muscle growth and strength gains',
        'Provides energy for intense workouts',
        'Enhances recovery after exercise',
        'Helps achieve weight gain goals',
      ],
      foodGroups: [
        'Lean proteins', 'Complex carbs', 'Healthy fats', 'Calorie-dense foods', 'Protein supplements'
      ],
      mealPlan: {
        'breakfast': ['Protein pancakes with banana and honey', 'Breakfast burrito with eggs, cheese, and potatoes'],
        'lunch': ['Double chicken breast with pasta and vegetables', 'Beef and rice bowl with avocado'],
        'dinner': ['Salmon with sweet potato and olive oil', 'Steak with baked potato and vegetables'],
        'snacks': ['Protein shake with oats and peanut butter', 'Trail mix with nuts and dried fruit', 'Greek yogurt with granola']
      },
      caloriesPerDay: 2600,
      suitableFor: ['Muscle building', 'Weight gain', 'Strength athletes', 'Hard gainers'],
    ));
    
    return dietPlans;
  }

  // Helper method to ensure meal plans have content and accurate calories
  void _fillEmptyMealPlans(Map<String, List<String>> mealPlan, String dietType) async {
    try {
      // Get access token for FatSecret API
      final accessToken = await _getFatSecretAccessToken();
      
      // Define target calories based on diet type
      int targetCalories = _getDietCalories(dietType, 25, 'bulking'); // Default to bulking calories
      
      // Common foods and their calorie values from FatSecret API
      Map<String, int> foodCalories = {
        'rice': 130, // per 1/2 cup cooked
        'chicken breast': 165, // per 3 oz
        'salmon': 175, // per 3 oz
        'eggs': 70, // per large egg
        'oatmeal': 150, // per 1/2 cup dry
        'banana': 105, // per medium
        'sweet potato': 100, // per 1/2 cup
        'broccoli': 30, // per 1 cup
        'avocado': 240, // per medium
        'almonds': 160, // per 1 oz
        'greek yogurt': 100, // per 1/2 cup
        'quinoa': 110, // per 1/2 cup cooked
        'pasta': 200, // per 1 cup cooked
        'bread': 80, // per slice
        'cheese': 110, // per 1 oz
        'milk': 90, // per 1 cup
        'protein powder': 120, // per scoop
        'peanut butter': 190, // per 2 tbsp
        'olive oil': 120, // per 1 tbsp
        'butter': 100, // per 1 tbsp
      };

      // Calculate calories for each meal time
      Map<String, int> mealCalories = {
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
        'snacks': 0
      };

      // Fill empty meal categories with accurate calorie calculations
      for (var mealTime in ['breakfast', 'lunch', 'dinner', 'snacks']) {
        if (mealPlan[mealTime] == null) {
          mealPlan[mealTime] = [];
        }
        
        if (mealPlan[mealTime]!.isEmpty) {
          // Create balanced meals based on target calories
          List<String> meals = [];
          int mealTargetCalories = 0;
          
          switch (mealTime) {
            case 'breakfast':
              mealTargetCalories = (targetCalories * 0.25).round(); // 25% of daily calories
              meals = _createMealWithCalories(mealTargetCalories, foodCalories, ['oatmeal', 'eggs', 'banana', 'milk', 'almonds']);
              break;
            case 'lunch':
              mealTargetCalories = (targetCalories * 0.35).round(); // 35% of daily calories
              meals = _createMealWithCalories(mealTargetCalories, foodCalories, ['rice', 'chicken breast', 'broccoli', 'avocado']);
              break;
            case 'dinner':
              mealTargetCalories = (targetCalories * 0.30).round(); // 30% of daily calories
              meals = _createMealWithCalories(mealTargetCalories, foodCalories, ['salmon', 'quinoa', 'sweet potato', 'olive oil']);
              break;
            case 'snacks':
              mealTargetCalories = (targetCalories * 0.10).round(); // 10% of daily calories
              meals = _createMealWithCalories(mealTargetCalories, foodCalories, ['greek yogurt', 'protein powder', 'peanut butter']);
              break;
          }
          
          mealPlan[mealTime] = meals;
          mealCalories[mealTime] = mealTargetCalories;
        }
      }

      // Verify total calories
      int totalCalories = mealCalories.values.reduce((a, b) => a + b);
      if (totalCalories != targetCalories) {
        print('Warning: Total calories ($totalCalories) do not match target ($targetCalories)');
      }
    } catch (e) {
      print('Error filling meal plans: $e');
      // Fallback to default meals if API fails
      _fillDefaultMeals(mealPlan, dietType);
    }
  }

  // Helper method to create a meal with specific calorie target
  List<String> _createMealWithCalories(int targetCalories, Map<String, int> foodCalories, List<String> availableFoods) {
    List<String> meal = [];
    int currentCalories = 0;
    
    // Sort foods by calorie density
    availableFoods.sort((a, b) => foodCalories[b]!.compareTo(foodCalories[a]!));
    
    for (var food in availableFoods) {
      if (currentCalories >= targetCalories) break;
      
      int foodCal = foodCalories[food]!;
      int servings = ((targetCalories - currentCalories) / foodCal).ceil();
      
      if (servings > 0) {
        meal.add('$servings serving(s) of $food (${foodCal * servings} kcal)');
        currentCalories += foodCal * servings;
      }
    }
    
    return meal;
  }

  // Fallback method for default meals
  void _fillDefaultMeals(Map<String, List<String>> mealPlan, String dietType) {
    final defaultMeals = {
      'breakfast': [
        '2 servings of oatmeal (300 kcal)',
        '2 eggs (140 kcal)',
        '1 banana (105 kcal)',
        '1 cup milk (90 kcal)'
      ],
      'lunch': [
        '2 servings of rice (260 kcal)',
        '6 oz chicken breast (330 kcal)',
        '1 cup broccoli (30 kcal)',
        '1/2 avocado (120 kcal)'
      ],
      'dinner': [
        '6 oz salmon (350 kcal)',
        '1 cup quinoa (220 kcal)',
        '1 cup sweet potato (200 kcal)',
        '1 tbsp olive oil (120 kcal)'
      ],
      'snacks': [
        '1 cup greek yogurt (200 kcal)',
        '1 scoop protein powder (120 kcal)',
        '2 tbsp peanut butter (190 kcal)'
      ]
    };
    
    for (var mealTime in ['breakfast', 'lunch', 'dinner', 'snacks']) {
      if (mealPlan[mealTime] == null || mealPlan[mealTime]!.isEmpty) {
        mealPlan[mealTime] = defaultMeals[mealTime]!;
      }
    }
  }
} 