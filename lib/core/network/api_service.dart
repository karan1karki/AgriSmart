// lib/core/network/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://your-api-domain.com/api"; // Replace with your Laravel/Django URL

  // Register User
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  // Login User
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      body: jsonEncode({"email": email, "password": password}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }
}