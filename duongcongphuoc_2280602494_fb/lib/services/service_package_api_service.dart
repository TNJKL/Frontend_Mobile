import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/service_package.dart';
import '../config/config_url.dart';

class ServicePackageApiService {
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
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET: api/ServicePackage
  static Future<List<ServicePackage>> getServicePackages() async {
    final headers = await _buildHeaders();
    final res = await http.get(Uri.parse('$baseUrl/ServicePackage'), headers: headers);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => ServicePackage.fromJson(e)).toList();
    }
    throw Exception('Failed to load service packages: ${res.statusCode}');
  }

  // GET: api/ServicePackage/5
  static Future<ServicePackage> getServicePackage(int id) async {
    final headers = await _buildHeaders();
    final res = await http.get(Uri.parse('$baseUrl/ServicePackage/$id'), headers: headers);
    if (res.statusCode == 200) {
      return ServicePackage.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to load service package: ${res.statusCode}');
  }

  // POST: api/ServicePackage
  static Future<ServicePackage> createServicePackage(ServicePackage package) async {
    final headers = await _buildHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/ServicePackage'),
      headers: headers,
      body: json.encode(package.toJson()..remove('id')),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ServicePackage.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to create service package: ${res.statusCode} - ${res.body}');
  }

  // PUT: api/ServicePackage/5
  static Future<void> updateServicePackage(ServicePackage package) async {
    final headers = await _buildHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/ServicePackage/${package.id}'),
      headers: headers,
      body: json.encode(package.toJson()),
    );
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('Failed to update service package: ${res.statusCode} - ${res.body}');
  }

  // DELETE: api/ServicePackage/5
  static Future<void> deleteServicePackage(int id) async {
    final headers = await _buildHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/ServicePackage/$id'), headers: headers);
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('Failed to delete service package: ${res.statusCode} - ${res.body}');
  }

  // POST: api/ServicePackage/Apply/{packageId}/ToEvent/{eventId}
  static Future<void> applyPackageToEvent(int packageId, int eventId, {int tableCount = 1}) async {
    final headers = await _buildHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/ServicePackage/Apply/$packageId/ToEvent/$eventId?tableCount=$tableCount'),
      headers: headers,
    );
    if (res.statusCode == 200) return;
    throw Exception('Failed to apply package: ${res.statusCode} - ${res.body}');
  }
}
