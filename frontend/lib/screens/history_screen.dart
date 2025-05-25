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
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        throw Exception("User not logged in");
      }

      final bmiHistory = await ApiService.getBMIHistory(userId);

      final List<Map<String, dynamic>> data = bmiHistory.map<Map<String, dynamic>>((item) {
        return {
          'image_path': item['image_path'] ?? 'assets/images/placeholder.png',
          'date': DateTime.parse(item['created_at']),
        };
      }).toList();

      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading history: $e");
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
          ? const Center(child: Text("No food scan records yet."))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final bgColor = _colors[index % _colors.length];
                  final formattedDate = DateFormat('dd MMM yyyy – hh:mm a').format(item['date'] as DateTime);

                  return Card(
                    color: bgColor,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(item['image_path']),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/placeholder.png', width: 80, height: 80, fit: BoxFit.cover),
      );
    } else if (File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }
  }
}