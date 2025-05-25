import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';

class ServerConfigScreen extends StatefulWidget {
  final VoidCallback onConfigSaved;

  const ServerConfigScreen({Key? key, required this.onConfigSaved})
    : super(key: key);

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        _serverUrlController.text = savedUrl;
      });
    } else {
      // Default to the current value in ApiService
      setState(() {
        _serverUrlController.text = ApiService.baseUrl;
      });
    }
  }

  Future<void> _saveServerUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = _serverUrlController.text.trim();

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', url);

      // Update the API service
      ApiService.updateBaseUrl(url);

      // Test connection
      final testUrl = Uri.parse("$url/");
      final response = await Future.delayed(
        const Duration(seconds: 1), // Add a small delay to show loading
        () => http
            .get(testUrl)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException("Connection timed out"),
            ),
      );

      if (response.statusCode == 200) {
        // Connection successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connection successful!"),
              backgroundColor: Colors.green,
            ),
          );

          // Call the callback to navigate back
          widget.onConfigSaved();
        }
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      String errorMsg;
      if (e is SocketException) {
        errorMsg =
            "Connection failed: Could not connect to the server. Please check that:\n"
            "1. The server is running\n"
            "2. The URL is correct\n"
            "3. Your device is connected to the network";
      } else if (e is TimeoutException) {
        errorMsg =
            "Connection timed out: The server took too long to respond. Please check that:\n"
            "1. The server is running\n"
            "2. The URL is correct\n"
            "3. Your device is connected to the same network as the server";
      } else {
        errorMsg = "Connection failed: ${e.toString()}";
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "Testing all possible connections...";
    });

    try {
      final results = await ApiService.testServerConnection();

      // Format results for display
      final StringBuffer resultText = StringBuffer();
      resultText.writeln("Connection Test Results:");
      resultText.writeln("------------------------");

      bool anySuccess = false;
      String? workingUrl;

      results.forEach((url, result) {
        resultText.writeln("$url: ${result ? '✅ SUCCESS' : '❌ FAILED'}");
        if (result) {
          anySuccess = true;
          workingUrl = url;
        }
      });

      if (anySuccess && workingUrl != null) {
        resultText.writeln("\n✅ Found working connection at: $workingUrl");
        resultText.writeln("You can use this URL in your configuration.");

        // Update the text field with the working URL
        setState(() {
          _serverUrlController.text = workingUrl!;
        });
      } else {
        resultText.writeln("\n❌ No working connections found.");
        resultText.writeln("Please check that:");
        resultText.writeln("1. The server is running");
        resultText.writeln(
          "2. Your device is on the same network as the server",
        );
        resultText.writeln(
          "3. There are no firewall issues blocking the connection",
        );
      }

      setState(() {
        _errorMessage = resultText.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error during connection test: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server Configuration"),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Server URL",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  hintText: "http://192.168.4.86:5000",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.computer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter server URL';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "Connection Tips:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "• For Android emulators: use 10.0.2.2:5000\n"
                "• For iOS simulators: use 127.0.0.1:5000\n"
                "• For physical devices: use your computer's IP address (e.g., 192.168.4.86:5000)\n"
                "• Make sure your device is on the same network as the server\n"
                "• Ensure the backend server is running",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isLoading ? null : _testAllConnections,
                      child: const Text(
                        'Test All Connections',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isLoading ? null : _saveServerUrl,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Save and Test',
                                style: TextStyle(fontSize: 14),
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
