import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';

class PaymentService {
  Future<Map<String, dynamic>?> createPaymentUrl(double amount, {String? customerName, String? orderDescription}) async {
    try {
      final response = await http.post(
        Uri.parse('${Config_URL.baseUrl}/Payment/CreatePaymentUrl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'customerName': customerName,
          'orderDescription': orderDescription
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // {url: ..., txnRef: ...}
      } else {
        print('Failed to create payment url: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling payment api: $e');
      return null;
    }
  }

  Future<String> checkPaymentStatus(String txnRef) async {
    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/Payment/CheckStatus/$txnRef'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] ?? 'Unknown';
      }
    } catch (e) {
      print('Check status error: $e');
    }
    return 'Unknown';
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/Payment/History'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Get history error: $e');
    }
    return [];
  }
}
