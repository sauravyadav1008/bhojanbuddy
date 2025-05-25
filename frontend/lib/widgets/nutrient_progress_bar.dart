// lib/widgets/nutrient_progress_bar.dart
import 'package:flutter/material.dart';

class NutrientProgressBar extends StatelessWidget {
  final String nutrientName;
  final double currentValue;
  final double maxValue;
  final bool isHigherBetter;

  const NutrientProgressBar({
    Key? key,
    required this.nutrientName,
    required this.currentValue,
    required this.maxValue,
    this.isHigherBetter = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final double progress =
        maxValue > 0 ? (currentValue / maxValue).clamp(0.0, 1.0) : 0.0;

    // Determine color based on progress and whether higher is better
    Color progressColor;
    if (isHigherBetter) {
      // For nutrients like fiber, protein, calcium, iron where higher is better
      if (progress < 0.3) {
        progressColor = Colors.red;
      } else if (progress < 0.7) {
        progressColor = Colors.yellow;
      } else {
        progressColor = Colors.green;
      }
    } else {
      // For nutrients like sugar, fat, sodium where lower is better
      if (progress < 0.3) {
        progressColor = Colors.green;
      } else if (progress < 0.7) {
        progressColor = Colors.yellow;
      } else {
        progressColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nutrientName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${currentValue.toStringAsFixed(1)} / ${maxValue.toStringAsFixed(1)}${_getUnit(nutrientName)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
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
