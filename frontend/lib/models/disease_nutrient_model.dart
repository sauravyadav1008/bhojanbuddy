// lib/models/disease_nutrient_model.dart
class DiseaseNutrientModel {
  final String diseaseName;
  final List<String> nutrientsToMonitor;
  final String reason;

  DiseaseNutrientModel({
    required this.diseaseName,
    required this.nutrientsToMonitor,
    required this.reason,
  });

  // Add Depression/Anxiety to the list
  static Map<String, DiseaseNutrientModel> diseaseNutrientMap = {
    'Depression / Anxiety': DiseaseNutrientModel(
      diseaseName: 'Depression / Anxiety',
      nutrientsToMonitor: ['Fat', 'Fiber', 'Iron', 'Protein', 'Calories'],
      reason: 'Nutrients that influence mood and brain health',
    ),
    'Diabetes (Type 2)': DiseaseNutrientModel(
      diseaseName: 'Diabetes (Type 2)',
      nutrientsToMonitor: ['Carbs', 'Sugar', 'Fiber', 'Calories', 'Fat'],
      reason: 'Control blood sugar and weight',
    ),
    'Hypertension (High Blood Pressure)': DiseaseNutrientModel(
      diseaseName: 'Hypertension (High Blood Pressure)',
      nutrientsToMonitor: [
        'Sodium',
        'Fat',
        'Calories',
        'Saturated Fat',
        'Cholesterol',
      ],
      reason: 'Lower blood pressure and prevent heart risk',
    ),
    'Obesity': DiseaseNutrientModel(
      diseaseName: 'Obesity',
      nutrientsToMonitor: [
        'Calories',
        'Fat',
        'Carbs',
        'Sugar',
        'Protein',
        'Fiber',
      ],
      reason: 'Weight management and satiety',
    ),
    'Cardiovascular Disease': DiseaseNutrientModel(
      diseaseName: 'Cardiovascular Disease',
      nutrientsToMonitor: [
        'Saturated Fat',
        'Cholesterol',
        'Sodium',
        'Sugar',
        'Fiber',
        'Calories',
      ],
      reason: 'Reduce risk of heart attacks and strokes',
    ),
    'Hyperlipidemia (High Cholesterol)': DiseaseNutrientModel(
      diseaseName: 'Hyperlipidemia (High Cholesterol)',
      nutrientsToMonitor: [
        'Saturated Fat',
        'Cholesterol',
        'Fiber',
        'Fat',
        'Calories',
      ],
      reason: 'Improve HDL/LDL ratio',
    ),
    'Chronic Kidney Disease (CKD)': DiseaseNutrientModel(
      diseaseName: 'Chronic Kidney Disease (CKD)',
      nutrientsToMonitor: [
        'Protein',
        'Sodium',
        'Calcium',
        'Iron',
        'Cholesterol',
      ],
      reason: 'Kidney-friendly nutrient load',
    ),
    'Polycystic Ovary Syndrome (PCOS)': DiseaseNutrientModel(
      diseaseName: 'Polycystic Ovary Syndrome (PCOS)',
      nutrientsToMonitor: ['Carbs', 'Sugar', 'Protein', 'Fat', 'Calories'],
      reason: 'Improve insulin resistance and hormone balance',
    ),
    'Fatty Liver Disease (NAFLD)': DiseaseNutrientModel(
      diseaseName: 'Fatty Liver Disease (NAFLD)',
      nutrientsToMonitor: [
        'Sugar',
        'Fat',
        'Calories',
        'Saturated Fat',
        'Cholesterol',
      ],
      reason: 'Reduce liver fat and inflammation',
    ),
    'Anemia (Iron Deficiency)': DiseaseNutrientModel(
      diseaseName: 'Anemia (Iron Deficiency)',
      nutrientsToMonitor: ['Iron', 'Protein', 'Calories', 'Fat', 'Fiber'],
      reason: 'Promote hemoglobin and red blood cell production',
    ),
    'Hypothyroidism': DiseaseNutrientModel(
      diseaseName: 'Hypothyroidism',
      nutrientsToMonitor: ['Calories', 'Fat', 'Fiber', 'Iron', 'Calcium'],
      reason: 'Manage metabolism and nutrient absorption',
    ),
    'Osteoporosis': DiseaseNutrientModel(
      diseaseName: 'Osteoporosis',
      nutrientsToMonitor: [
        'Calcium',
        'Protein',
        'Calories',
        'Fat',
        'Cholesterol',
      ],
      reason: 'Support bone density and strength',
    ),
    'Metabolic Syndrome': DiseaseNutrientModel(
      diseaseName: 'Metabolic Syndrome',
      nutrientsToMonitor: ['Sugar', 'Sodium', 'Fat', 'Calories', 'Cholesterol'],
      reason: 'Targets combined risk factors',
    ),
    'Gout': DiseaseNutrientModel(
      diseaseName: 'Gout',
      nutrientsToMonitor: ['Protein', 'Fat', 'Calories', 'Cholesterol'],
      reason: 'Lower uric acid by moderating protein & purines',
    ),
    'Celiac Disease': DiseaseNutrientModel(
      diseaseName: 'Celiac Disease',
      nutrientsToMonitor: ['Fiber', 'Iron', 'Calcium', 'Calories', 'Fat'],
      reason: 'Nutrient replenishment post-malabsorption',
    ),
    'Irritable Bowel Syndrome (IBS) / Acid Reflux': DiseaseNutrientModel(
      diseaseName: 'Irritable Bowel Syndrome (IBS) / Acid Reflux',
      nutrientsToMonitor: ['Fat', 'Fiber', 'Calories'],
      reason: 'Reduce symptoms triggered by food',
    ),
    'Cancer Survivorship': DiseaseNutrientModel(
      diseaseName: 'Cancer Survivorship',
      nutrientsToMonitor: ['Protein', 'Calories', 'Fat', 'Sugar', 'Fiber'],
      reason: 'Recovery and immune support',
    ),
  };

  // Get nutrients to monitor for a list of diseases
  static List<String> getNutrientsForDiseases(List<String> diseases) {
    Set<String> nutrients = {};

    for (String disease in diseases) {
      if (diseaseNutrientMap.containsKey(disease)) {
        nutrients.addAll(diseaseNutrientMap[disease]!.nutrientsToMonitor);
      }
    }

    return nutrients.toList();
  }

  // Get reasons for monitoring nutrients for a specific disease
  static String getReasonForDisease(String disease) {
    if (diseaseNutrientMap.containsKey(disease)) {
      return diseaseNutrientMap[disease]!.reason;
    }
    return '';
  }
}
