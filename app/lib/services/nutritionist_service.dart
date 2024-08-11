import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tamotsu/services/auth_service.dart';

class NutritionistService {
  final String baseUrl;
  final AuthService authService;

  NutritionistService({required this.baseUrl, required this.authService});

  Future<Map<String, dynamic>> getNutritionistProfile() async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/nutritionists/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nutritionist profile');
    }
  }

  Future<Map<String, dynamic>> updateNutritionistProfile(Map<String, dynamic> profileData) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/nutritionists/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(profileData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update nutritionist profile');
    }
  }

  Future<Map<String, dynamic>> getNutritionistPublicProfile(String nutritionistId) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/nutritionists/$nutritionistId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nutritionist public profile');
    }
  }

  Future<Map<String, dynamic>> getNutritionistList({
    String? specialty,
    String? language,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final queryParams = {
      if (specialty != null) 'specialty': specialty,
      if (language != null) 'language': language,
      'page': page.toString(),
      'perPage': perPage.toString(),
    };

    final response = await http.get(
      Uri.parse('$baseUrl/nutritionists').replace(queryParameters: queryParams),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nutritionist list');
    }
  }
}
