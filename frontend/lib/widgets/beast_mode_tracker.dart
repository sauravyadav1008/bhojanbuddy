// lib/widgets/beast_mode_tracker.dart
import 'package:flutter/material.dart';
import '../services/nutrient_service.dart';

class BeastModeTracker extends StatefulWidget {
  final Map<String, dynamic> nutritionInfo;
  final VoidCallback? onSettingsTap;

  const BeastModeTracker({
    Key? key,
    required this.nutritionInfo,
    this.onSettingsTap,
  }) : super(key: key);

  @override
  State<BeastModeTracker> createState() => _BeastModeTrackerState();
}

class _BeastModeTrackerState extends State<BeastModeTracker> {
  Map<String, double> _currentNutrients = {};
  Map<String, double> _maxNutrients = {};
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

    // Get the nutrients from the current food item
    final caloriesInFood = _parseNutrientValue('calories');
    final proteinInFood = _parseNutrientValue('protein');

    // Get current and max values
    final currentCalories = _currentNutrients['Calories'] ?? 0.0;
    final maxCalories = _maxNutrients['Calories'] ?? 2000.0;
    final currentProtein = _currentNutrients['Protein'] ?? 0.0;
    final maxProtein = _maxNutrients['Protein'] ?? 50.0;

    // Calculate progress
    final caloriesProgress = (currentCalories / maxCalories).clamp(0.0, 1.0);
    final newCaloriesProgress =
        ((currentCalories + caloriesInFood) / maxCalories).clamp(0.0, 1.0);
    final proteinProgress = (currentProtein / maxProtein).clamp(0.0, 1.0);
    final newProteinProgress = ((currentProtein + proteinInFood) / maxProtein)
        .clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Beast Mode Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed:
                      widget.onSettingsTap ??
                      () => _showSettingsDialog(context),
                  tooltip: 'Set daily goals',
                ),
              ],
            ),
            const Divider(height: 24),

            // Calories Tracker
            _buildNutrientTracker(
              context,
              'Calories',
              currentCalories,
              caloriesInFood,
              maxCalories,
              caloriesProgress,
              newCaloriesProgress,
              'kcal',
              Colors.orange,
            ),

            const SizedBox(height: 16),

            // Protein Tracker
            _buildNutrientTracker(
              context,
              'Protein',
              currentProtein,
              proteinInFood,
              maxProtein,
              proteinProgress,
              newProteinProgress,
              'g',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTracker(
    BuildContext context,
    String nutrient,
    double currentValue,
    double foodValue,
    double maxValue,
    double progress,
    double newProgress,
    String unit,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nutrient,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Text('${currentValue.toStringAsFixed(1)}'),
                Text(
                  ' + ${foodValue.toStringAsFixed(1)} → ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(currentValue + foodValue).toStringAsFixed(1)} / ${maxValue.toStringAsFixed(1)} $unit',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 15,
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
                  height: 15,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% of daily goal',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final caloriesController = TextEditingController(
      text: _maxNutrients['Calories']?.toString() ?? '2000',
    );
    final proteinController = TextEditingController(
      text: _maxNutrients['Protein']?.toString() ?? '50',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beast Mode Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set your daily nutrition goals:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calories (kcal)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                // Update max nutrients
                final newMaxNutrients = Map<String, double>.from(_maxNutrients);
                newMaxNutrients['Calories'] =
                    double.tryParse(caloriesController.text) ?? 2000.0;
                newMaxNutrients['Protein'] =
                    double.tryParse(proteinController.text) ?? 50.0;

                await NutrientService.updateMaxNutrients(newMaxNutrients);

                // Reload data
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadNutrientData();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
