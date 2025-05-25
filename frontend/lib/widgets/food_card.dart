import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String label;
  final double confidence;
  final Map<String, dynamic> nutrition;

  const FoodCard({
    Key? key,
    required this.label,
    required this.confidence,
    required this.nutrition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🍽 $label",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.pink[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ...nutrition.entries.map(
              (entry) => Text(
                "${entry.key}: ${entry.value}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
