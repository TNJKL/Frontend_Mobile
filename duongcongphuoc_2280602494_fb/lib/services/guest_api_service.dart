import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../Models/guest.dart';

class GuestApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Dùng IP LAN của máy tính để cả Emulator và Máy thật đều vào được
      return 'http://192.168.88.138:5226/api/GuestApi';
    }
    return 'http://localhost:5226/api/GuestApi';
  }

  Future<List<Guest>> getGuests(int eventId) async {
    final response = await http.get(Uri.parse('$baseUrl/event/$eventId')).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Guest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load guests');
    }
  }

  Future<void> createGuest(Guest guest) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(guest.toJson()),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw Exception('Failed to create guest: ${response.body}');
    }
  }

  Future<void> updateGuest(Guest guest) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${guest.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(guest.toJson()),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 204) {
      throw Exception('Failed to update guest');
    }
  }

  Future<void> deleteGuest(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete guest');
    }
  }

  Future<void> importGuests(int eventId, File file) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/import/$eventId'));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to import guests: $respStr');
    }
  }
  Future<Guest> checkInGuest(int id) async {
    // 1. Fetch current guest info
    try {
      final getResponse = await http.get(Uri.parse('$baseUrl/$id')).timeout(const Duration(seconds: 10));
      if (getResponse.statusCode == 200) {
        final guest = Guest.fromJson(json.decode(getResponse.body));
        
        // 2. Update status to 'Attended'
        final updatedGuest = Guest(
          id: guest.id,
          eventId: guest.eventId,
          fullName: guest.fullName,
          email: guest.email,
          phone: guest.phone,
          guestType: guest.guestType,
          rsvpStatus: 'Attended', // Mark as Attended
          plusOneCount: guest.plusOneCount,
          tableNumber: guest.tableNumber,
          dietaryRequirements: guest.dietaryRequirements,
          notes: guest.notes,
          giftReceived: guest.giftReceived,
          giftDescription: guest.giftDescription
        );

        // 3. Send update
        await updateGuest(updatedGuest);
        return updatedGuest;
      } else {
        throw Exception('Guest not found');
      }
    } catch(e) {
      throw Exception('Check-in failed: $e');
    }
  }
}
