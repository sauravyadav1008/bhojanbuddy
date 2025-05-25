// lib/screens/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'bmi_input_screen.dart';
import 'disease_selection_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool isSwasthyaMode = true;

  void _proceed() {
    final selectedMode = isSwasthyaMode ? 'swasthya' : 'beast';

    if (isSwasthyaMode) {
      // For Swasthya mode, go to disease selection first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseSelectionScreen(mode: selectedMode),
        ),
      );
    } else {
      // For Beast mode, go directly to BMI input
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BMIInputScreen(mode: selectedMode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isSwasthyaMode ? Colors.pink : Colors.green;
    final Color backgroundColor =
        isSwasthyaMode ? Colors.pink[50]! : Colors.green[50]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top image - only shown in Swasthya mode
            if (isSwasthyaMode) ...[
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Image.asset(
                  'assets/images/patient.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ] else ...[
              const SizedBox(height: 40),
            ],

            // Middle section with mode selection
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: activeColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isSwasthyaMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color:
                                    isSwasthyaMode
                                        ? Colors.pink[100]
                                        : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(28),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "🩺 Swasthya Mode",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isSwasthyaMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color:
                                    !isSwasthyaMode
                                        ? Colors.green[100]
                                        : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(28),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "💪 Beast Mode",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Bottom image - only shown in Beast mode
            if (!isSwasthyaMode) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Image.asset(
                  'assets/images/swasthya.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ] else ...[
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
