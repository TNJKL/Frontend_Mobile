import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? Config_URL.baseUrl;

  // Lấy JWT token từ SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final token = await _getToken();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers, token),
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final token = await _getToken();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers, token),
      body: jsonEncode(body),
    );
  }

  // Các phương thức PUT, DELETE nếu cần
  Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final token = await _getToken();
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers, token),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    final token = await _getToken();
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(headers, token),
    );
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers, String? token) {
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Thêm JWT token nếu có
    if (token != null) {
      defaultHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    
    return defaultHeaders;
  }
}

