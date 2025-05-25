// lib/screens/history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _errorMessage;
  final List<Color> _colors = [
    Colors.green.shade100,
    Colors.pink.shade100,
    Colors.yellow.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the current user ID
      final userId = await ApiService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception("User not logged in");
      }
      
      // Get BMI history from the API
      final bmiHistory = await ApiService.getBMIHistory(userId);
      
      // Convert the API response to the format needed for the UI
      final List<Map<String, dynamic>> data = bmiHistory.map<Map<String, dynamic>>((item) {
        return {
          'image_path': 'assets/images/placeholder.png',
          'date': DateTime.parse(item['created_at']),
          'bmi': item['bmi'],
          'bmi_category': item['bmi_category'],
          'height': item['height'],
          'weight': item['weight'],
          'mode': item['mode'],
        };
      }).toList();
      
      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading BMI history: $e");
      setState(() {
        _errorMessage = "Failed to load history: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      body: _history.isEmpty
          ? const Center(child: Text("No BMI records yet."))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final bgColor = _colors[index % _colors.length];
                  final formattedDate = DateFormat(
                    'dd MMM yyyy – hh:mm a',
                  ).format(item['date'] as DateTime);
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "BMI: ${item['bmi'].toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item['bmi_category'],
                                style: TextStyle(
                                  color: _getBmiCategoryColor(item['bmi_category']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Height: ${item['height']} cm"),
                          Text("Weight: ${item['weight']} kg"),
                          Text("Mode: ${item['mode']}"),
                          const SizedBox(height: 8),
                          Text(
                            "Date: $formattedDate",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
  
  Color _getBmiCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
