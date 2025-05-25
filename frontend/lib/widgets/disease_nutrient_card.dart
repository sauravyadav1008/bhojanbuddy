// lib/widgets/disease_nutrient_card.dart
import 'package:flutter/material.dart';
import '../models/disease_nutrient_model.dart';
import 'nutrient_progress_bar.dart';

class DiseaseNutrientCard extends StatelessWidget {
  final String diseaseName;
  final Map<String, double> currentNutrients;
  final Map<String, double> maxNutrients;

  const DiseaseNutrientCard({
    Key? key,
    required this.diseaseName,
    required this.currentNutrients,
    required this.maxNutrients,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final diseaseModel = DiseaseNutrientModel.diseaseNutrientMap[diseaseName];

    if (diseaseModel == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diseaseName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              diseaseModel.reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 24),
            ...diseaseModel.nutrientsToMonitor.map((nutrient) {
              final current = currentNutrients[nutrient] ?? 0.0;
              final max = maxNutrients[nutrient] ?? 100.0;
              final isHigherBetter = _isHigherBetter(nutrient);

              return NutrientProgressBar(
                nutrientName: nutrient,
                currentValue: current,
                maxValue: max,
                isHigherBetter: isHigherBetter,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  bool _isHigherBetter(String nutrient) {
    // Nutrients where higher values are generally better
    final higherBetterNutrients = ['Fiber', 'Protein', 'Calcium', 'Iron'];

    return higherBetterNutrients.contains(nutrient);
  }
}
