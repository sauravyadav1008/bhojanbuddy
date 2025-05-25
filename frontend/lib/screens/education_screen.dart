// lib/screens/education_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  List<dynamic> _allFacts = [];
  List<dynamic> _displayedFacts = [];
  final List<Color> _colors = [
    Colors.green.shade100,
    Colors.pink.shade100,
    Colors.yellow.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  Future<void> _loadFacts() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/food_facts.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _allFacts = jsonData;
        _refreshFacts();
      });
    } catch (e) {
      print('Error loading food facts: $e');
      // Show a simple error message if facts can't be loaded
      setState(() {
        _allFacts = [
          {
            'id': 0,
            'fact': 'Unable to load food facts. Please try again later.',
          },
        ];
        _displayedFacts = _allFacts;
      });
    }
  }

  void _refreshFacts() {
    final random = Random();
    final shuffled = List<dynamic>.from(_allFacts)..shuffle(random);
    setState(() {
      _displayedFacts = shuffled.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshFacts,
              tooltip: "Show more facts",
            ),
          ),
        ),
        Expanded(
          child:
              _displayedFacts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    itemCount: _displayedFacts.length,
                    itemBuilder: (context, index) {
                      final fact = _displayedFacts[index];
                      final bgColor = _colors[index % _colors.length];
                      return Card(
                        color: bgColor,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Did You Know?",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fact['fact'] ?? 'No fact available',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "Source: BhojanBuddy",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
