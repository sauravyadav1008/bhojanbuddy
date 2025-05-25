import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Default to localhost for emulator, but allow override
  static String baseUrl =
      "http://192.168.4.86:5000"; // Using computer's IP address for physical device

  // Fallback URLs to try if the main URL fails
  static final List<String> fallbackUrls = [
    "http://10.0.2.2:5000", // For Android emulator
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://192.168.1.100:5000", // Adding the IP address from the error logs
    "http://0.0.0.0:5000", // Try binding to all interfaces
  ];

  // Error message for server not running
  static const String serverNotRunningMessage =
      "Server not running. Please make sure the BhojanBuddy server is started by running:\n\n"
      "python run_server.py\n\n"
      "from the project root directory, then try again.";

  // Method to update the base URL at runtime
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print("API base URL updated to: $baseUrl");
  }

  // Method to get the current user ID from shared preferences
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // Method to test server connection
  static Future<Map<String, bool>> testServerConnection() async {
    Map<String, bool> results = {};
    List<String> allUrls = [baseUrl, ...fallbackUrls];

    for (String url in allUrls) {
      try {
        print("Testing connection to: $url");
        final response = await http
            .get(Uri.parse("$url/"))
            .timeout(const Duration(seconds: 5));

        results[url] = response.statusCode == 200;
        print("Connection to $url: ${results[url]} (${response.statusCode})");

        if (results[url] == true) {
          // If this URL works, update the base URL
          updateBaseUrl(url);
          break;
        }
      } catch (e) {
        results[url] = false;
        print("Connection to $url failed: $e");
      }
    }

    return results;
  }

  // User Management
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String preferred_mode = "swasthya",
    List<String>? diseases,
  }) async {
    // Create a list of URLs to try, starting with the main baseUrl
    List<String> urlsToTry = [baseUrl, ...fallbackUrls];
    SocketException? lastSocketException;

    final requestBody = {
      "full_name": name,
      "email": email,
      "password": password,
      "preferred_mode": preferred_mode,
      if (diseases != null && diseases.isNotEmpty) "diseases": diseases,
      if (age != null) "age": age,
      if (gender != null) "gender": gender,
      if (height != null) "height": height,
      if (weight != null) "weight": weight,
    };

    // Try each URL in sequence
    for (String currentUrl in urlsToTry) {
      try {
        final url = Uri.parse("$currentUrl/auth/register");
        print("Trying to register user at: $url");
        print("Request body: ${json.encode(requestBody)}");

        final response = await http
            .post(
              url,
              headers: {"Content-Type": "application/json"},
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 10));

        print("Register response status: ${response.statusCode}");
        print("Register response body: ${response.body}");

        if (response.statusCode == 201) {
          // If successful, update the baseUrl to the working URL for future requests
          if (currentUrl != baseUrl) {
            print("Updating baseUrl to working server: $currentUrl");
            baseUrl = currentUrl;
            // Save the working URL to preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('server_url', currentUrl);
          }
          return json.decode(response.body);
        } else {
          String errorMessage;
          try {
            final errorData = json.decode(response.body);
            errorMessage =
                errorData['detail'] ??
                "Registration failed with status code: ${response.statusCode}";
          } catch (e) {
            errorMessage =
                "Registration failed with status code: ${response.statusCode}, body: ${response.body}";
          }
          throw Exception(errorMessage);
        }
      } catch (e) {
        print("Registration error with $currentUrl: $e");
        if (e is SocketException) {
          // Save the exception but continue to the next URL
          lastSocketException = e;
          continue;
        } else if (e is! TimeoutException) {
          // For non-connection errors, rethrow immediately
          rethrow;
        }
      }
    }

    // If we've tried all URLs and still have a connection error
    if (lastSocketException != null) {
      throw Exception(
        "Connection failed. Please check your internet connection and server settings. "
        "Make sure the BhojanBuddy server is running and accessible.",
      );
    } else {
      throw Exception(
        "Connection timed out. Please check your server settings and try again.",
      );
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    // Create a list of URLs to try, starting with the main baseUrl
    List<String> urlsToTry = [baseUrl, ...fallbackUrls];
    SocketException? lastSocketException;

    // Try each URL in sequence
    for (String currentUrl in urlsToTry) {
      try {
        final url = Uri.parse("$currentUrl/auth/login");
        print("Trying to login user at: $url");

        // Using FormData as the backend expects OAuth2PasswordRequestForm
        final response = await http
            .post(
              url,
              headers: {"Content-Type": "application/x-www-form-urlencoded"},
              body: {
                "username": email, // OAuth2 form uses 'username' field
                "password": password,
              },
            )
            .timeout(const Duration(seconds: 10));

        print("Login response status: ${response.statusCode}");
        print("Login response body: ${response.body}");

        if (response.statusCode == 200) {
          final tokenData = json.decode(response.body);

          // If successful, update the baseUrl to the working URL for future requests
          if (currentUrl != baseUrl) {
            print("Updating baseUrl to working server: $currentUrl");
            baseUrl = currentUrl;
            // Save the working URL to preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('server_url', currentUrl);
          }

          // Save user ID to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', tokenData['user_id']);
          await prefs.setString('access_token', tokenData['access_token']);

          return {
            'id': tokenData['user_id'],
            'token': tokenData['access_token'],
          };
        } else {
          String errorMessage;
          try {
            final errorData = json.decode(response.body);
            errorMessage =
                errorData['detail'] ??
                "Login failed with status code: ${response.statusCode}";
          } catch (e) {
            errorMessage =
                "Login failed with status code: ${response.statusCode}, body: ${response.body}";
          }
          throw Exception(errorMessage);
        }
      } catch (e) {
        print("Login error with $currentUrl: $e");
        if (e is SocketException) {
          // Save the exception but continue to the next URL
          lastSocketException = e;
          continue;
        } else if (e is! TimeoutException) {
          // For non-connection errors, rethrow immediately
          rethrow;
        }
      }
    }

    // If we've tried all URLs and still have a connection error
    if (lastSocketException != null) {
      throw Exception(
        "Connection failed. Please check your internet connection and server settings. "
        "Make sure the BhojanBuddy server is running and accessible.",
      );
    } else {
      throw Exception(
        "Connection timed out. Please check your server settings and try again.",
      );
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    final url = Uri.parse("$baseUrl/users/$userId");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? "Failed to get user profile");
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? password,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? mode,
    List<String>? diseases,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    final url = Uri.parse("$baseUrl/users/me");
    final Map<String, dynamic> updateData = {};

    if (name != null) updateData['full_name'] = name;
    if (email != null) updateData['email'] = email;
    if (password != null) updateData['password'] = password;
    if (age != null) updateData['age'] = age;
    if (gender != null) updateData['gender'] = gender;
    if (height != null) updateData['height'] = height;
    if (weight != null) updateData['weight'] = weight;
    if (mode != null) updateData['preferred_mode'] = mode;
    if (diseases != null) updateData['diseases'] = diseases;

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? "Failed to update profile");
    }
  }

  // BMI Management
  static Future<Map<String, dynamic>> saveBMIRecord({
    required int userId,
    required double height,
    required double weight,
    required double bmi,
    required String bmiCategory,
    String mode = 'swasthya',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    // The correct endpoint based on backend routes
    final url = Uri.parse("$baseUrl/api/bmi");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "user_id": userId,
        "height": height,
        "weight": weight,
        "bmi": bmi,
        "bmi_category": bmiCategory,
        "mode": mode,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData['detail'] ??
            "Failed to save BMI record: ${response.statusCode}";
      } catch (e) {
        errorMessage = "Failed to save BMI record: ${response.statusCode}";
      }
      throw Exception(errorMessage);
    }
  }

  static Future<List<dynamic>> getBMIHistory(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    // The correct endpoint based on backend routes
    final url = Uri.parse("$baseUrl/api/bmi/$userId");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData['detail'] ??
            "Failed to get BMI history: ${response.statusCode}";
      } catch (e) {
        errorMessage = "Failed to get BMI history: ${response.statusCode}";
      }
      throw Exception(errorMessage);
    }
  }

  // Food Management
  static Future<Map<String, dynamic>> saveFoodEntry({
    required int userId,
    required File imageFile,
    required String foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    // The correct endpoint based on backend routes
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/foods/log"),
    );

    // Add authorization header
    request.headers["Authorization"] = "Bearer $token";

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Add form fields
    request.fields['user_id'] = userId.toString();
    request.fields['food_name'] = foodName;
    if (calories != null) request.fields['calories'] = calories.toString();
    if (protein != null) request.fields['protein'] = protein.toString();
    if (carbs != null) request.fields['carbs'] = carbs.toString();
    if (fat != null) request.fields['fat'] = fat.toString();

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        return json.decode(responseData.body);
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(responseData.body);
          errorMessage =
              errorData['detail'] ??
              "Failed to save food entry: ${response.statusCode}";
        } catch (e) {
          errorMessage =
              "Failed to save food entry: ${response.statusCode}, ${responseData.body}";
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception("Failed to save food entry: $e");
    }
  }

  static Future<List<dynamic>> getFoodHistory(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    // The correct endpoint based on backend routes
    final url = Uri.parse("$baseUrl/foods/log/$userId");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData['detail'] ??
            "Failed to get food history: ${response.statusCode}";
      } catch (e) {
        errorMessage = "Failed to get food history: ${response.statusCode}";
      }
      throw Exception(errorMessage);
    }
  }

  // Food Prediction (ML Integration)
  static Future<Map<String, dynamic>> predictFood(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/predict"));

    // Add authorization header
    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return json.decode(responseData.body);
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(responseData.body);
          errorMessage =
              errorData['detail'] ??
              "Prediction failed: ${response.statusCode}";
        } catch (e) {
          errorMessage =
              "Prediction failed: ${response.statusCode}, ${responseData.body}";
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception("Prediction failed: $e");
    }
  }

  // Feedback
  static Future<void> sendFeedback({
    required String imageName,
    required String correctLabel,
    required String predictedLabel,
    required double confidence,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception("Not authenticated");
    }

    final url = Uri.parse("$baseUrl/feedback");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "image_name": imageName,
        "correct_label": correctLabel,
        "predicted_label": predictedLabel,
        "confidence": confidence,
      }),
    );

    if (response.statusCode != 201) {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData['detail'] ??
            "Feedback submission failed: ${response.statusCode}";
      } catch (e) {
        errorMessage = "Feedback submission failed: ${response.statusCode}";
      }
      throw Exception(errorMessage);
    }
  }

  // Helper method to diagnose connection issues
  static Future<Map<String, dynamic>> diagnoseServerConnection() async {
    Map<String, dynamic> results = {};

    // Try all URLs including the main one
    List<String> allUrls = [baseUrl, ...fallbackUrls];

    // Add some common local network IPs that might work
    final localIps = [
      "http://192.168.0.1:5000",
      "http://192.168.1.1:5000",
      "http://192.168.1.100:5000",
      "http://192.168.0.100:5000",
    ];

    // Add any IPs that aren't already in our list
    for (String ip in localIps) {
      if (!allUrls.contains(ip)) {
        allUrls.add(ip);
      }
    }

    for (String url in allUrls) {
      try {
        print("Testing connection to: $url");
        final response = await http
            .get(Uri.parse("$url/"))
            .timeout(const Duration(seconds: 3));

        results[url] = {
          'success': response.statusCode == 200,
          'statusCode': response.statusCode,
          'message':
              response.statusCode == 200
                  ? "Connection successful"
                  : "Server returned status code: ${response.statusCode}",
        };
      } catch (e) {
        results[url] = {
          'success': false,
          'error': e.toString(),
          'message': "Connection failed: ${e.toString()}",
        };
      }
    }

    // If we found a working URL, update the baseUrl
    for (String url in results.keys) {
      if (results[url]['success'] == true) {
        print("Found working URL: $url");
        baseUrl = url;

        // Save the working URL to preferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('server_url', url);
          print("Saved working URL to preferences: $url");
        } catch (e) {
          print("Error saving URL to preferences: $e");
        }

        break;
      }
    }

    return results;
  }
}
