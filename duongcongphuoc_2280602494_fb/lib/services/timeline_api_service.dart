import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/event_timeline.dart';
import '../config/config_url.dart';

class TimelineApiService {
  static String get baseUrl => '${Config_URL.baseUrl}/EventTimelineApi';

  // Fetch all timelines for an event
  Future<List<EventTimeline>> getTimelinesByEventId(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/event/$eventId'));
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => EventTimeline.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load timelines: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching timelines: $e');
      throw Exception('Failed to load timelines');
    }
  }

  // Create a new timeline
  Future<EventTimeline> createTimeline(EventTimeline timeline) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(timeline.toJson()),
      );
      if (response.statusCode == 201) {
        return EventTimeline.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create timeline: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating timeline: $e');
    }
  }

  // Update a timeline
  Future<void> updateTimeline(EventTimeline timeline) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${timeline.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(timeline.toJson()),
      );
      if (response.statusCode != 204) {
        throw Exception('Failed to update timeline: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating timeline: $e');
    }
  }

  // Delete a timeline
  Future<void> deleteTimeline(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode != 204) {
        throw Exception('Failed to delete timeline');
      }
    } catch (e) {
      throw Exception('Error deleting timeline: $e');
    }
  }

  // Create template
  Future<void> createTemplate(int eventId, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/template/$eventId?type=$type'),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create template: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating template: $e');
    }
  }
}
