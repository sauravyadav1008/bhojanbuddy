import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'screens/mode_selection_screen.dart';
import 'screens/server_config_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the API service with the correct URL
  try {
    print("Initializing API service...");
    await ApiService.initializeApiService();
    print("API service initialized with base URL: ${ApiService.baseUrl}");
  } catch (e) {
    print("Error initializing API service: $e");
  }

  runApp(const BhojanBuddyApp());
}

class BhojanBuddyApp extends StatelessWidget {
  const BhojanBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BhojanBuddy',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool _isPasswordVisible = false;
  String? errorMessage;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  void _navigateToServerConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ServerConfigScreen(
              onConfigSaved: () {
                Navigator.of(context).pop();
              },
            ),
      ),
    );
  }

  Future<void> _checkIfLoggedIn() async {
    final userId = await ApiService.getCurrentUserId();
    if (userId != null) {
      // User is already logged in, navigate to the main screen
      _navigateToMainScreen();
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
    );
  }

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null; // Clear any error messages when switching forms
    });
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isLogin) {
        // Login logic
        final userData = await ApiService.loginUser(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        // Store user data if needed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userData['id']);

        // Navigate to main screen
        _navigateToMainScreen();
      } else {
        // Register logic
        print("Starting registration process...");
        try {
          // Test server connection before registration
          print("Testing server connection before registration...");
          await ApiService.testServerConnection();

          // Proceed with registration
          final registerResponse = await ApiService.registerUser(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            preferred_mode: "swasthya", // Default mode
          );

          print("Registration successful: $registerResponse");

          // After successful registration, automatically log in
          print("Attempting to login after registration...");
          final loginData = await ApiService.loginUser(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

          print("Login successful: $loginData");

          // Store user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', loginData['id']);

          // Navigate to main screen
          _navigateToMainScreen();
        } catch (registrationError) {
          print("Registration error: $registrationError");
          throw registrationError;
        }
      }
    } catch (e) {
      print("Form submission error: $e");
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToServerConfig,
            tooltip: 'Server Configuration',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo/Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.yellow.shade200,
                child: Icon(
                  Icons.person_rounded,
                  size: 70,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                isLogin ? 'Welcome Back!' : 'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade400,
                ),
              ),
              const SizedBox(height: 30),

              // Name field (only for register)
              if (!isLogin)
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    filled: true,
                    fillColor: Colors.yellow.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (!isLogin && (value == null || value.isEmpty)) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              if (!isLogin) const SizedBox(height: 20),

              // Email field
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.green.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password field with show/hide toggle
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.pink.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (!isLogin && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Error message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: isLoading ? null : submitForm,
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            isLogin ? 'Login' : 'Register',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
              ),

              const SizedBox(height: 20),

              // Toggle form
              TextButton(
                onPressed: isLoading ? null : toggleForm,
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                  style: TextStyle(color: Colors.pink.shade600),
                ),
              ),

              // Connection test button
              if (errorMessage != null &&
                  (errorMessage!.contains("Connection failed") ||
                      errorMessage!.contains("Connection timed out") ||
                      errorMessage!.contains("SocketException")))
                Column(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                          errorMessage = "Testing connection...";
                        });

                        try {
                          // Try to connect to the server
                          final response = await http
                              .get(Uri.parse("${ApiService.baseUrl}/"))
                              .timeout(const Duration(seconds: 5));

                          setState(() {
                            isLoading = false;
                            if (response.statusCode == 200) {
                              errorMessage =
                                  "Server is reachable! You can try again.";
                            } else {
                              errorMessage =
                                  "Server returned status code: ${response.statusCode}";
                            }
                          });
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            errorMessage =
                                "Connection test failed: ${e.toString()}";
                          });
                        }
                      },
                      icon: const Icon(Icons.network_check, color: Colors.blue),
                      label: const Text(
                        "Test Current Connection",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                          errorMessage = "Testing all possible connections...";
                        });

                        try {
                          // Test all possible connections
                          final results =
                              await ApiService.testServerConnection();

                          // Check if any connection was successful
                          bool anySuccess = false;
                          String? workingUrl;

                          results.forEach((url, result) {
                            if (result) {
                              // result is a boolean, not a map
                              anySuccess = true;
                              workingUrl = url;
                            }
                          });

                          setState(() {
                            isLoading = false;
                            if (anySuccess && workingUrl != null) {
                              errorMessage =
                                  "Found working connection at: $workingUrl\n"
                                  "This URL has been saved. You can try again now.";
                            } else {
                              errorMessage =
                                  "No working connections found. Please check that:\n"
                                  "1. The server is running\n"
                                  "2. Your device is on the same network as the server\n"
                                  "3. There are no firewall issues blocking the connection";
                            }
                          });
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            errorMessage =
                                "Error during connection test: ${e.toString()}";
                          });
                        }
                      },
                      icon: const Icon(Icons.search, color: Colors.green),
                      label: const Text(
                        "Find Working Connection",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
