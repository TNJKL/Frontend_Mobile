import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class UserApiService {
  static String get baseUrl => Config_URL.baseUrl;

  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<dynamic>> getUsers() async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/UserApi'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    final headers = await _buildHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/UserApi/$userId/role'),
      headers: headers,
      body: json.encode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update role: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> toggleUserLock(String userId) async {
    final headers = await _buildHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/UserApi/$userId/lock'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update lock status: ${response.statusCode}');
    }
  }
}
