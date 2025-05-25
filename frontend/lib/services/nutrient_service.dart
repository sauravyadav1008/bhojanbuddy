// lib/services/nutrient_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NutrientService {
  // Default recommended daily values for nutrients
  static final Map<String, double> defaultMaxNutrients = {
    'Calories': 2000.0,
    'Protein': 50.0,
    'Fat': 70.0,
    'Saturated Fat': 20.0,
    'Carbs': 300.0,
    'Sugar': 50.0,
    'Fiber': 25.0,
    'Sodium': 2300.0,
    'Cholesterol': 300.0,
    'Calcium': 1000.0,
    'Iron': 18.0,
  };

  // Get the current nutrient values for today
  static Future<Map<String, double>> getCurrentNutrients() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString();

    final String? nutrientsJson = prefs.getString('nutrients_$today');
    if (nutrientsJson == null) {
      return {};
    }

    try {
      final Map<String, dynamic> data = json.decode(nutrientsJson);
      return data.map((key, value) => MapEntry(key, value.toDouble()));
    } catch (e) {
      return {};
    }
  }

  // Add nutrients from a food item
  static Future<void> addNutrients(Map<String, double> nutrients) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString();

    // Get current nutrients
    Map<String, double> currentNutrients = await getCurrentNutrients();

    // Add new nutrients
    nutrients.forEach((nutrient, value) {
      if (currentNutrients.containsKey(nutrient)) {
        currentNutrients[nutrient] = currentNutrients[nutrient]! + value;
      } else {
        currentNutrients[nutrient] = value;
      }
    });

    // Save updated nutrients
    await prefs.setString('nutrients_$today', json.encode(currentNutrients));
  }

  // Reset nutrients for today
  static Future<void> resetNutrients() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString();
    await prefs.remove('nutrients_$today');
  }

  // Get maximum recommended values for nutrients
  static Future<Map<String, double>> getMaxNutrients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? maxNutrientsJson = prefs.getString('max_nutrients');

    if (maxNutrientsJson == null) {
      return defaultMaxNutrients;
    }

    try {
      final Map<String, dynamic> data = json.decode(maxNutrientsJson);
      return data.map((key, value) => MapEntry(key, value.toDouble()));
    } catch (e) {
      return defaultMaxNutrients;
    }
  }

  // Update maximum recommended values for nutrients
  static Future<void> updateMaxNutrients(
    Map<String, double> maxNutrients,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('max_nutrients', json.encode(maxNutrients));
  }

  // Get date string in format YYYY-MM-DD
  static String _getDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
