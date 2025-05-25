// lib/screens/result_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/disease_nutrient_model.dart';
import '../services/nutrient_service.dart';
import '../widgets/disease_nutrient_card.dart';
import '../widgets/nutrient_snack_bar.dart';
import '../widgets/beast_mode_tracker.dart';
import 'settings_screen.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> predictionResult;

  const ResultScreen({
    Key? key,
    required this.imageFile,
    required this.predictionResult,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String _mode = 'beast';
  List<String> _selectedDiseases = [];
  Map<String, double> _currentNutrients = {};
  Map<String, double> _maxNutrients = {};
  bool _nutrientsAdded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user mode
      final mode = prefs.getString('preferred_mode') ?? 'beast';

      // Load selected diseases
      final diseases = prefs.getStringList('selected_diseases') ?? [];

      // Load current and max nutrients
      final currentNutrients = await NutrientService.getCurrentNutrients();
      final maxNutrients = await NutrientService.getMaxNutrients();

      setState(() {
        _mode = mode;
        _selectedDiseases = diseases;
        _currentNutrients = currentNutrients;
        _maxNutrients = maxNutrients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNutrientsToDaily() async {
    if (_nutrientsAdded) return;

    final nutritionInfo = widget.predictionResult['nutrition'] ?? {};
    final Map<String, double> nutrients = {
      'Calories': _parseNutrientValue(nutritionInfo['calories']),
      'Protein': _parseNutrientValue(nutritionInfo['protein']),
      'Carbs': _parseNutrientValue(nutritionInfo['carbs']),
      'Fat': _parseNutrientValue(nutritionInfo['fat']),
      'Fiber': _parseNutrientValue(nutritionInfo['fiber']),
      'Sugar': _parseNutrientValue(nutritionInfo['sugar']),
      'Sodium': _parseNutrientValue(nutritionInfo['sodium']),
      'Cholesterol': _parseNutrientValue(nutritionInfo['cholesterol']),
      'Saturated Fat': _parseNutrientValue(nutritionInfo['saturated_fat']),
      'Calcium': _parseNutrientValue(nutritionInfo['calcium']),
      'Iron': _parseNutrientValue(nutritionInfo['iron']),
    };

    await NutrientService.addNutrients(nutrients);

    // Reload current nutrients
    final currentNutrients = await NutrientService.getCurrentNutrients();

    setState(() {
      _currentNutrients = currentNutrients;
      _nutrientsAdded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nutrients added to your daily tracking'),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _parseNutrientValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final foodName = widget.predictionResult['label'] ?? 'Unknown Food';
    final confidence = (widget.predictionResult['confidence'] ?? 0.0) * 100;
    final nutritionInfo = widget.predictionResult['nutrition'] ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(foodName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.file(
                widget.imageFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                foodName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                "Confidence: ${confidence.toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Nutrition Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNutritionTable(nutritionInfo),
            const SizedBox(height: 20),
            if (widget.predictionResult['description'] != null) ...[
              const Text(
                "About this dish",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.predictionResult['description'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],

            // Add button to add nutrients to daily tracking
            if (!_nutrientsAdded)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Add to Daily Tracking"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _addNutrientsToDaily,
                ),
              ),

            // Show appropriate tracker based on mode
            if (_mode == 'beast') ...[
              const SizedBox(height: 30),
              const Text(
                "Beast Mode Tracking",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                BeastModeTracker(
                  nutritionInfo: nutritionInfo,
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ).then((_) => _loadUserData());
                  },
                ),
            ] else if (_mode == 'swasthya' && _selectedDiseases.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                "Health Monitoring",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                NutrientSnackBar(
                  selectedDiseases: _selectedDiseases,
                  nutritionInfo: nutritionInfo,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTable(Map<String, dynamic> nutritionInfo) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNutritionRow(
              "Calories",
              "${nutritionInfo['calories'] ?? 'N/A'} kcal",
            ),
            _buildNutritionRow(
              "Protein",
              "${nutritionInfo['protein'] ?? 'N/A'} g",
            ),
            _buildNutritionRow(
              "Carbohydrates",
              "${nutritionInfo['carbs'] ?? 'N/A'} g",
            ),
            _buildNutritionRow("Fat", "${nutritionInfo['fat'] ?? 'N/A'} g"),
            _buildNutritionRow("Fiber", "${nutritionInfo['fiber'] ?? 'N/A'} g"),
            _buildNutritionRow("Sugar", "${nutritionInfo['sugar'] ?? 'N/A'} g"),

            // Additional nutrients that might be important for health conditions
            if (nutritionInfo['sodium'] != null)
              _buildNutritionRow("Sodium", "${nutritionInfo['sodium']} mg"),
            if (nutritionInfo['cholesterol'] != null)
              _buildNutritionRow(
                "Cholesterol",
                "${nutritionInfo['cholesterol']} mg",
              ),
            if (nutritionInfo['saturated_fat'] != null)
              _buildNutritionRow(
                "Saturated Fat",
                "${nutritionInfo['saturated_fat']} g",
              ),
            if (nutritionInfo['calcium'] != null)
              _buildNutritionRow("Calcium", "${nutritionInfo['calcium']} mg"),
            if (nutritionInfo['iron'] != null)
              _buildNutritionRow("Iron", "${nutritionInfo['iron']} mg"),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
