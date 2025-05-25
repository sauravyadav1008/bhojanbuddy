// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/nutrient_service.dart';
import '../models/disease_nutrient_model.dart';
import '../widgets/nutrient_snack_bar.dart';
import '../widgets/beast_mode_tracker.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import '../widgets/lottie_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _message;
  Map<String, dynamic>? _result;
  String _mode = 'beast';
  List<String> _selectedDiseases = [];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
        _message = null;
      });
    }
  }

  Future<void> _uploadAndPredict() async {
    if (_selectedImage == null) return;
    setState(() {
      _isLoading = true;
      _message = null;
      _result = null;
    });
    try {
      final result = await ApiService.predictFood(_selectedImage!);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResultView() {
    if (_result == null) return const SizedBox();
    final isConfident = _result!['status'] == 'confident';
    final confidence = (_result!['confidence'] ?? 0.0) * 100;

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          "Accuracy: ${confidence.toStringAsFixed(1)}%",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (isConfident && confidence > 70)
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ResultScreen(
                          imageFile: _selectedImage!,
                          predictionResult: _result!,
                        ),
                  ),
                ),
            child: const Text("View Prediction Result"),
          )
        else if (_result!['options'] != null)
          Column(
            children: [
              const Text("Prediction uncertain. Choose the closest match:"),
              ...(_result!['options'] as List)
                  .map(
                    (opt) => ListTile(
                      title: Text(opt['label']),
                      trailing: Text(
                        "${(opt['confidence'] * 100).toStringAsFixed(1)}%",
                      ),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ResultScreen(
                                    imageFile: _selectedImage!,
                                    predictionResult: _result!,
                                  ),
                            ),
                          ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Model predicted wrong? Switch Gear"),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Model switching coming soon!"),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('preferred_mode') ?? 'beast';
    final diseases = prefs.getStringList('selected_diseases') ?? [];

    setState(() {
      _mode = mode;
      _selectedDiseases = diseases;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_selectedImage != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedImage!, height: 250),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Take a photo of your food 📸",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera 📸"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Gallery 🖼️"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _uploadAndPredict,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const LottieLoader()
                          : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search),
                              SizedBox(width: 8),
                              Text(
                                "Identify Food 🍽️",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(_message!, style: const TextStyle(color: Colors.red)),
                ],
                _buildResultView(),

                // Show appropriate tracker based on mode
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  if (_mode == 'beast')
                    BeastModeTracker(
                      nutritionInfo: _result!['nutrition'] ?? {},
                      onSettingsTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ).then((_) => _loadUserPreferences());
                      },
                    )
                  else if (_mode == 'swasthya' && _selectedDiseases.isNotEmpty)
                    NutrientSnackBar(
                      selectedDiseases: _selectedDiseases,
                      nutritionInfo: _result!,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
