import 'dart:convert';
import '../Models/wedding_task.dart';
import 'api_client.dart';

class TaskApiService {
  final ApiClient _client = ApiClient();

  // Tasks
  Future<List<WeddingTask>> getTasksByEventId(int eventId) async {
    final response = await _client.get('/WeddingTaskApi/event/$eventId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WeddingTask.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> createTask(WeddingTask task) async {
    final response = await _client.post('/WeddingTaskApi', body: {
      'EventId': task.eventId,
      'Title': task.title,
      'Description': task.description,
      'Category': task.category,
      'Priority': task.priority,
      'Status': task.status,
      'DueDate': task.dueDate?.toIso8601String(),
      'ReminderDate': task.reminderDate?.toIso8601String(),
      'AssignedToUserId': task.assignedToUserId, // Optional
    });

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create task: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateTask(WeddingTask task) async {
    final response = await _client.put('/WeddingTaskApi/${task.id}', body: {
      'Id': task.id,
      'EventId': task.eventId,
      'Title': task.title,
      'Description': task.description,
      'Category': task.category,
      'Priority': task.priority,
      'Status': task.status,
      'DueDate': task.dueDate?.toIso8601String(),
      'CompletedDate': task.completedDate?.toIso8601String(),
      'ReminderDate': task.reminderDate?.toIso8601String(),
      'AssignedToUserId': task.assignedToUserId,
    });

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await _client.delete('/WeddingTaskApi/$id');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> generateTemplateTasks(int eventId) async {
    final response = await _client.post('/WeddingTaskApi/template/$eventId');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to generate template tasks: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTaskStats(int eventId) async {
    final response = await _client.get('/WeddingTaskApi/stats/$eventId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stats');
    }
  }
}
