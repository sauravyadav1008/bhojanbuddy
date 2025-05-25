// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/nutrient_service.dart';
import '../models/user_model.dart';
import '../models/disease_nutrient_model.dart';
import '../widgets/disease_nutrient_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _user;
  String _errorMessage = '';
  Map<String, double> _currentNutrients = {};
  Map<String, double> _maxNutrients = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load user profile
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      // Load user data from API
      final userData = await ApiService.getUserProfile(userId);

      // Load nutrient data
      final currentNutrients = await NutrientService.getCurrentNutrients();
      final maxNutrients = await NutrientService.getMaxNutrients();

      // If user has no diseases in API, try to get from shared preferences
      List<String> diseases = [];
      if (userData['diseases'] == null ||
          (userData['diseases'] as List).isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        diseases = prefs.getStringList('selected_diseases') ?? [];
      } else {
        diseases = List<String>.from(userData['diseases']);
      }

      // If user has no mode in API, try to get from shared preferences
      String mode = userData['preferred_mode'] ?? 'beast';
      if (mode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        mode = prefs.getString('preferred_mode') ?? 'beast';
      }

      setState(() {
        _user = UserModel.fromJson({
          ...userData,
          'id': userId,
          'diseases': diseases,
          'preferred_mode': mode,
        });
        _currentNutrients = currentNutrients;
        _maxNutrients = maxNutrients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadUserProfile());
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_user == null) {
      return const Center(child: Text('No user data available'));
    }

    final Color modeColor =
        _user!.mode == 'swasthya' ? Colors.pink : Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar and name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: modeColor.withOpacity(0.2),
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: modeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _user!.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Mode information
          _buildInfoCard(
            title: 'Selected Mode',
            content:
                _user!.mode == 'swasthya'
                    ? '🩺 Swasthya Mode'
                    : '💪 Beast Mode',
            icon: Icons.fitness_center,
            color: modeColor,
          ),

          const SizedBox(height: 16),

          // Health conditions (only for Swasthya mode)
          if (_user!.mode == 'swasthya') ...[
            _buildDiseasesList(
              title: 'Health Conditions',
              diseases: _user!.diseases,
              icon: Icons.medical_services,
              color: modeColor,
            ),
            const SizedBox(height: 16),

            // Nutrient monitoring section
            if (_user!.diseases.isNotEmpty) ...[
              const Text(
                'Nutrient Monitoring',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Get all unique nutrients to monitor from all selected diseases
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Combined Nutrients to Monitor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Based on all your health conditions',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(height: 24),
                      ...DiseaseNutrientModel.getNutrientsForDiseases(
                        _user!.diseases,
                      ).map((nutrient) {
                        final current = _currentNutrients[nutrient] ?? 0.0;
                        final max = _maxNutrients[nutrient] ?? 100.0;
                        final isHigherBetter = [
                          'Fiber',
                          'Protein',
                          'Calcium',
                          'Iron',
                        ].contains(nutrient);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    nutrient,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${current.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}${_getUnit(nutrient)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value:
                                      max > 0
                                          ? (current / max).clamp(0.0, 1.0)
                                          : 0.0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getColorForProgress(
                                      max > 0
                                          ? (current / max).clamp(0.0, 1.0)
                                          : 0.0,
                                      isHigherBetter,
                                    ),
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Show individual disease cards
              ..._user!.diseases.map((disease) {
                return DiseaseNutrientCard(
                  diseaseName: disease,
                  currentNutrients: _currentNutrients,
                  maxNutrients: _maxNutrients,
                );
              }).toList(),
              const SizedBox(height: 16),

              // Reset daily nutrients button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Daily Nutrients'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await NutrientService.resetNutrients();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily nutrients reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUserProfile();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Basic information
          _buildInfoCard(
            title: 'Basic Information',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_user!.age != null)
                  _buildInfoRow('Age', '${_user!.age} years'),
                if (_user!.gender != null)
                  _buildInfoRow('Gender', _user!.gender!),
                if (_user!.height != null)
                  _buildInfoRow('Height', '${_user!.height} cm'),
                if (_user!.weight != null)
                  _buildInfoRow('Weight', '${_user!.weight} kg'),
              ],
            ),
            icon: Icons.person,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required dynamic content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            content is Widget
                ? content
                : Text(
                  content.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseasesList({
    required String title,
    required List<String> diseases,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            diseases.isEmpty
                ? const Text(
                  'No health conditions selected',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      diseases
                          .map(
                            (disease) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: color,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      disease,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
