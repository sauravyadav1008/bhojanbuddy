// lib/screens/history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
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
    // Mock example: replace with loading from DB or local file
    final List<Map<String, dynamic>> data = [
      {
        'image_path': 'assets/images/placeholder.png',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'calories': 320,
      },
      {
        'image_path': 'assets/images/placeholder.png',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'calories': 410,
      },
    ];
    setState(() => _history = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _history.isEmpty
              ? const Center(child: Text("No predictions yet."))
              : ListView.builder(
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
                    child: ListTile(
                      leading: Image.asset(
                        item['image_path'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text("Calories: ${item['calories']} kcal"),
                      subtitle: Text("Date: $formattedDate"),
                    ),
                  );
                },
              ),
    );
  }
}
