// lib/screens/disease_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'bmi_input_screen.dart';

class DiseaseSelectionScreen extends StatefulWidget {
  final String mode;

  const DiseaseSelectionScreen({Key? key, required this.mode})
    : super(key: key);

  @override
  State<DiseaseSelectionScreen> createState() => _DiseaseSelectionScreenState();
}

class _DiseaseSelectionScreenState extends State<DiseaseSelectionScreen> {
  final List<String> _availableDiseases = [
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

  final Set<String> _selectedDiseases = {};
  bool _isLoading = false;

  void _toggleDisease(String disease) {
    setState(() {
      if (_selectedDiseases.contains(disease)) {
        _selectedDiseases.remove(disease);
      } else {
        _selectedDiseases.add(disease);
      }
    });
  }

  Future<void> _proceed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save selected diseases to user profile
      final userId = await ApiService.getCurrentUserId();
      if (userId != null) {
        await ApiService.updateUserProfile(
          userId: userId,
          mode: widget.mode,
          diseases: _selectedDiseases.toList(),
        );

        // Save to shared preferences for quick access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'selected_diseases',
          _selectedDiseases.toList(),
        );
        await prefs.setString('preferred_mode', widget.mode);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BMIInputScreen(mode: widget.mode)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor =
        widget.mode == 'swasthya' ? Colors.pink : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'swasthya'
              ? '🩺 Swasthya Mode Setup'
              : '💪 Beast Mode Setup',
        ),
        backgroundColor: themeColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select your health conditions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _availableDiseases.length,
                      itemBuilder: (context, index) {
                        final disease = _availableDiseases[index];
                        final isSelected = _selectedDiseases.contains(disease);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                              color:
                                  isSelected ? themeColor : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: ListTile(
                            title: Text(disease),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color: themeColor,
                                    )
                                    : const Icon(Icons.circle_outlined),
                            onTap: () => _toggleDisease(disease),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
