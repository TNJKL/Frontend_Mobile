import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';

class AdminService {
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/AdminApi/DashboardStats'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dashboard stats: $e');
    }
    return {
      'totalEvents': 0,
      'totalUsers': 0,
      'upcomingEvents': 0,
      'pendingApprovals': 0,
      'totalVendors': 0,
      'totalRevenue': 0.0,
    };
  }
}
