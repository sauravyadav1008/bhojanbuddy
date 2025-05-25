// lib/screens/bmi_input_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class BMIInputScreen extends StatefulWidget {
  final String mode;
  const BMIInputScreen({super.key, required this.mode});

  @override
  State<BMIInputScreen> createState() => _BMIInputScreenState();
}

class _BMIInputScreenState extends State<BMIInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);
      final age = int.tryParse(_ageController.text);

      if (weight != null && height != null && height > 0 && age != null) {
        final bmi = weight / ((height / 100) * (height / 100));

        // Determine BMI category
        String bmiCategory;
        if (bmi < 18.5) {
          bmiCategory = "Underweight";
        } else if (bmi < 25) {
          bmiCategory = "Normal";
        } else if (bmi < 30) {
          bmiCategory = "Overweight";
        } else {
          bmiCategory = "Obese";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🎯 Your BMI is ${bmi.toStringAsFixed(1)} - $bmiCategory",
            ),
          ),
        );

        try {
          // Get user ID
          final userId = await ApiService.getCurrentUserId();
          if (userId != null) {
            // Save BMI record
            await ApiService.saveBMIRecord(
              userId: userId,
              height: height,
              weight: weight,
              bmi: bmi,
              bmiCategory: bmiCategory,
              mode: widget.mode,
            );

            // Update user profile with height, weight and age
            await ApiService.updateUserProfile(
              userId: userId,
              height: height,
              weight: weight,
              age: age,
            );
          }

          if (mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${e.toString()}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color topColor =
        widget.mode == 'swasthya' ? Colors.pink : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'swasthya' ? "Swasthya Mode" : "Beast Mode"),
        backgroundColor: topColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset('assets/images/bhojanbuddy.png', height: 180),
            const SizedBox(height: 20),
            Text(
              "Let's personalize your experience",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Age (years)"),
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? "Enter age" : null,
                  ),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Weight (kg)"),
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? "Enter weight" : null,
                  ),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Height (cm)"),
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? "Enter height" : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Submit & Continue"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: topColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
