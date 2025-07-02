import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://your-server-ip:5000/api';
  static String? authToken;

  // Helper method for making authenticated requests
  static Future<http.Response> _authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    switch (method.toLowerCase()) {
      case 'get':
        return await http.get(url, headers: headers);
      case 'post':
        return await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      case 'put':
        return await http.put(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      case 'delete':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Unsupported HTTP method');
    }
  }

  // User registration
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'register',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // User login
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['token'];
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Create food donation
  static Future<Map<String, dynamic>> createFoodDonation({
    required String foodCategory,
    required String foodType,
    required String quantity,
    String? description,
    required Map<String, dynamic> address,
    required DateTime availableFrom,
    required DateTime availableTo,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'donations',
      body: {
        'foodCategory': foodCategory,
        'foodType': foodType,
        'quantity': quantity,
        'description': description,
        'address': address,
        'availableFrom': availableFrom.toIso8601String(),
        'availableTo': availableTo.toIso8601String(),
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create donation: ${response.body}');
    }
  }

  // Create food request
  static Future<Map<String, dynamic>> createFoodRequest({
    required String foodCategory,
    required String foodType,
    required String quantity,
    String? description,
    required Map<String, dynamic> address,
    required DateTime neededBy,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'requests',
      body: {
        'foodCategory': foodCategory,
        'foodType': foodType,
        'quantity': quantity,
        'description': description,
        'address': address,
        'neededBy': neededBy.toIso8601String(),
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create request: ${response.body}');
    }
  }

  // Submit food inspection
  static Future<void> submitInspection({
    required String donationId,
    required int qualityRating,
    required DateTime expirationDate,
    required String notes,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'inspections',
      body: {
        'donationId': donationId,
        'qualityRating': qualityRating,
        'expirationDate': expirationDate.toIso8601String(),
        'notes': notes,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit inspection: ${response.body}');
    }
  }

  // Complete volunteer registration
  static Future<void> completeVolunteerRegistration({
    required bool hasVehicle,
    String? vehicleType,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required List<String> availability,
    required List<String> preferredTasks,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'volunteers',
      body: {
        'hasVehicle': hasVehicle,
        'vehicleType': vehicleType,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'availability': availability,
        'preferredTasks': preferredTasks,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to complete volunteer registration: ${response.body}');
    }
  }
}