// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nutrient_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedMode = 'beast';
  List<String> _selectedDiseases = [];
  Map<String, double> _maxNutrients = {};
  bool _isLoading = true;
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('preferred_mode') ?? 'beast';
      final diseases = prefs.getStringList('selected_diseases') ?? [];
      final maxNutrients = await NutrientService.getMaxNutrients();

      setState(() {
        _selectedMode = mode;
        _selectedDiseases = diseases;
        _maxNutrients = maxNutrients;
        _caloriesController.text =
            (_maxNutrients['Calories'] ?? 2000).toString();
        _proteinController.text = (_maxNutrients['Protein'] ?? 50).toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_mode', _selectedMode);
      await prefs.setStringList('selected_diseases', _selectedDiseases);

      // Update max nutrients
      final newMaxNutrients = Map<String, double>.from(_maxNutrients);
      newMaxNutrients['Calories'] =
          double.tryParse(_caloriesController.text) ?? 2000.0;
      newMaxNutrients['Protein'] =
          double.tryParse(_proteinController.text) ?? 50.0;
      await NutrientService.updateMaxNutrients(newMaxNutrients);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildModeSelector(),
                    const SizedBox(height: 30),

                    if (_selectedMode == 'beast') ...[
                      _buildBeastModeSettings(),
                    ] else if (_selectedMode == 'swasthya') ...[
                      _buildSwasthyaModeSettings(),
                    ],

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your preferred mode:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            RadioListTile<String>(
              title: const Text('Beast Mode'),
              subtitle: const Text('Focus on calories and protein tracking'),
              value: 'beast',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Swasthya Mode'),
              subtitle: const Text(
                'Health-focused tracking based on conditions',
              ),
              value: 'swasthya',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeastModeSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beast Mode Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set your daily nutrition goals:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Daily Calories (kcal)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Daily Protein (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Today\'s Tracking'),
              onPressed: () async {
                await NutrientService.resetNutrients();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Today\'s tracking has been reset'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwasthyaModeSettings() {
    // List of available health conditions
    final availableConditions = [
      'Depression / Anxiety',
      'Diabetes (Type 2)',
      'Hypertension (High Blood Pressure)',
      'Obesity',
      'Cardiovascular Disease',
      'Hyperlipidemia (High Cholesterol)',
      'Chronic Kidney Disease (CKD)',
      'Polycystic Ovary Syndrome (PCOS)',
      'Fatty Liver Disease (NAFLD)',
      'Anemia (Iron Deficiency)',
      'Hypothyroidism',
      'Osteoporosis',
      'Metabolic Syndrome',
      'Gout',
      'Celiac Disease',
      'Irritable Bowel Syndrome (IBS) / Acid Reflux',
      'Cancer Survivorship',
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Swasthya Mode Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select your health conditions:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...availableConditions.map((condition) {
              return CheckboxListTile(
                title: Text(condition),
                value: _selectedDiseases.contains(condition),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (!_selectedDiseases.contains(condition)) {
                        _selectedDiseases.add(condition);
                      }
                    } else {
                      _selectedDiseases.remove(condition);
                    }
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Today\'s Tracking'),
              onPressed: () async {
                await NutrientService.resetNutrients();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Today\'s tracking has been reset'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            ),
          ],
        ),
      ),
    );
  }
}
