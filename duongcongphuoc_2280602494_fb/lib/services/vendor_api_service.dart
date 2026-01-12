import 'dart:convert';
import '../Models/vendor.dart';
import '../Models/event_vendor.dart';
import 'api_client.dart';

class VendorApiService {
  final ApiClient _client = ApiClient();

  // --- Vendor Directory (Global) ---

  Future<List<Vendor>> getVendors() async {
    final response = await _client.get('/VendorApi');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Vendor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vendors');
    }
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _client.post('/VendorApi', body: vendor.toJson());
    if (response.statusCode == 201) {
      return Vendor.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create vendor');
    }
  }

  Future<void> updateVendor(Vendor vendor) async {
    final response = await _client.put('/VendorApi/${vendor.id}', body: vendor.toJson());
    if (response.statusCode != 204) {
      throw Exception('Failed to update vendor');
    }
  }

  Future<void> deleteVendor(int id) async {
    final response = await _client.delete('/VendorApi/$id');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete vendor');
    }
  }

  // --- Event Vendors (Hiring) ---

  // Get contracts for a specific vendor (Admin)
  Future<List<EventVendor>> getContractsByVendorId(int vendorId) async {
    final response = await _client.get('/EventVendorApi/vendor/$vendorId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventVendor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vendor contracts: ${response.statusCode}');
    }
  }

  Future<List<EventVendor>> getEventVendors(int eventId) async {
    final response = await _client.get('/EventVendorApi/event/$eventId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventVendor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load event vendors');
    }
  }

  Future<EventVendor> createEventVendor(EventVendor eventVendor) async {
    final response = await _client.post('/EventVendorApi', body: eventVendor.toJson());
    if (response.statusCode == 200) {
      return EventVendor.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to hire vendor');
    }
  }

  Future<void> updateEventVendor(EventVendor eventVendor) async {
    final response = await _client.put('/EventVendorApi/${eventVendor.id}', body: eventVendor.toJson());
    if (response.statusCode != 204) {
      throw Exception('Failed to update contract');
    }
  }

  Future<void> deleteEventVendor(int id) async {
    final response = await _client.delete('/EventVendorApi/$id');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete contract');
    }
  }
}
