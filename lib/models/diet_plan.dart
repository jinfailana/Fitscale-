class DietPlan {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> benefits;
  final List<String> foodGroups;
  final Map<String, List<String>> mealPlan; // breakfast, lunch, dinner, snacks
  final int caloriesPerDay;
  final List<String> suitableFor; // weight loss, muscle gain, etc.

  DietPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.benefits,
    required this.foodGroups,
    required this.mealPlan,
    required this.caloriesPerDay,
    required this.suitableFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'benefits': benefits,
      'foodGroups': foodGroups,
      'mealPlan': mealPlan,
      'caloriesPerDay': caloriesPerDay,
      'suitableFor': suitableFor,
    };
  }

  factory DietPlan.fromMap(Map<String, dynamic> map) {
    return DietPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      benefits: List<String>.from(map['benefits']),
      foodGroups: List<String>.from(map['foodGroups']),
      mealPlan: Map<String, List<String>>.from(
        map['mealPlan'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      caloriesPerDay: map['caloriesPerDay'],
      suitableFor: List<String>.from(map['suitableFor']),
    );
  }
} 