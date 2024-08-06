import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://api.tamotsu-app.com';
  final String tokenKey = 'auth_token';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final token = json.decode(response.body)['token'];
      await _storeToken(token);
      return token;
    } else {
      throw Exception('ログインに失敗しました');
    }
  }

  Future<void> logout() async {
    await _removeToken();
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<bool> register(String email, String userType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'userType': userType,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('登録に失敗しました');
    }
  }

  Future<bool> verifyEmail(String email, String verificationCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'verificationCode': verificationCode,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('メール認証に失敗しました');
    }
  }

  Future<bool> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('パスワードリセットリクエストに失敗しました');
    }
  }
}
