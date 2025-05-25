// lib/widgets/nutrient_snack_bar.dart
import 'package:flutter/material.dart';
import '../models/disease_nutrient_model.dart';
import '../services/nutrient_service.dart';

class NutrientSnackBar extends StatefulWidget {
  final List<String> selectedDiseases;
  final Map<String, dynamic> nutritionInfo;

  const NutrientSnackBar({
    Key? key,
    required this.selectedDiseases,
    required this.nutritionInfo,
  }) : super(key: key);

  @override
  State<NutrientSnackBar> createState() => _NutrientSnackBarState();
}

class _NutrientSnackBarState extends State<NutrientSnackBar> {
  Map<String, double> _currentNutrients = {};
  Map<String, double> _maxNutrients = {};
  List<String> _nutrientsToMonitor = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNutrientData();
  }

  Future<void> _loadNutrientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the list of nutrients to monitor based on selected diseases
      _nutrientsToMonitor = DiseaseNutrientModel.getNutrientsForDiseases(
        widget.selectedDiseases,
      );

      // Load current and max nutrients
      final currentNutrients = await NutrientService.getCurrentNutrients();
      final maxNutrients = await NutrientService.getMaxNutrients();

      setState(() {
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

  // Parse nutrient value from the nutrition info
  double _parseNutrientValue(String nutrientName) {
    String key = nutrientName.toLowerCase();
    if (key == 'carbs') key = 'carbohydrates';
    if (key == 'saturated fat') key = 'saturated_fat';

    final value = widget.nutritionInfo[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nutrientsToMonitor.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrients to Monitor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your health conditions',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 24),
            ..._buildNutrientBars(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNutrientBars() {
    final List<Widget> bars = [];

    // Get the nutrients from the current food item
    final Map<String, double> foodNutrients = {};
    for (String nutrient in _nutrientsToMonitor) {
      foodNutrients[nutrient] = _parseNutrientValue(nutrient);
    }

    // Build a bar for each nutrient to monitor
    for (String nutrient in _nutrientsToMonitor) {
      final currentValue = _currentNutrients[nutrient] ?? 0.0;
      final maxValue = _maxNutrients[nutrient] ?? 100.0;
      final foodValue = foodNutrients[nutrient] ?? 0.0;

      // Calculate progress percentage
      final double progress =
          maxValue > 0 ? (currentValue / maxValue).clamp(0.0, 1.0) : 0.0;
      final double newProgress =
          maxValue > 0
              ? ((currentValue + foodValue) / maxValue).clamp(0.0, 1.0)
              : 0.0;

      // Determine color based on progress
      Color currentColor = _getColorForProgress(
        progress,
        _isHigherBetter(nutrient),
      );
      Color newColor = _getColorForProgress(
        newProgress,
        _isHigherBetter(nutrient),
      );

      bars.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nutrient,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '${currentValue.toStringAsFixed(1)}',
                        style: TextStyle(color: currentColor),
                      ),
                      Text(
                        ' + ${foodValue.toStringAsFixed(1)} → ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(currentValue + foodValue).toStringAsFixed(1)} / ${maxValue.toStringAsFixed(1)}${_getUnit(nutrient)}',
                        style: TextStyle(color: newColor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  // Background progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(currentColor),
                      minHeight: 10,
                    ),
                  ),
                  // Overlay to show what the new value would be
                  if (foodValue > 0)
                    Positioned(
                      left:
                          MediaQuery.of(context).size.width *
                          progress *
                          0.8, // Adjust for padding
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width *
                            (newProgress - progress) *
                            0.8,
                        height: 10,
                        decoration: BoxDecoration(
                          color: newColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return bars;
  }

  Color _getColorForProgress(double progress, bool isHigherBetter) {
    if (isHigherBetter) {
      // For nutrients like fiber, protein, calcium, iron where higher is better
      if (progress < 0.3) {
        return Colors.red;
      } else if (progress < 0.7) {
        return Colors.yellow.shade800;
      } else {
        return Colors.green;
      }
    } else {
      // For nutrients like sugar, fat, sodium where lower is better
      if (progress < 0.3) {
        return Colors.green;
      } else if (progress < 0.7) {
        return Colors.yellow.shade800;
      } else {
        return Colors.red;
      }
    }
  }

  bool _isHigherBetter(String nutrient) {
    // Nutrients where higher values are generally better
    final higherBetterNutrients = ['Fiber', 'Protein', 'Calcium', 'Iron'];

    return higherBetterNutrients.contains(nutrient);
  }

  String _getUnit(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return ' kcal';
      case 'protein':
      case 'fat':
      case 'carbs':
      case 'fiber':
      case 'sugar':
      case 'saturated fat':
        return ' g';
      case 'sodium':
      case 'calcium':
      case 'iron':
        return ' mg';
      case 'cholesterol':
        return ' mg';
      default:
        return '';
    }
  }
}
