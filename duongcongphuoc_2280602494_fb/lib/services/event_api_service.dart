import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../Models/event_category.dart';
import '../config/config_url.dart';

class EventApiService {
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
    } else {
      // Nếu không có token, vẫn trả về headers (backend sẽ trả về 401)
      // Điều này giúp frontend hiển thị thông báo rõ ràng hơn
    }
    return headers;
  }

  // Event APIs
  static Future<List<Event>> getEvents({DateTime? startDate, DateTime? endDate}) async {
    final headers = await _buildHeaders();
    String url = '$baseUrl/EventApi';
    
    if (startDate != null && endDate != null) {
      url += '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Event.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Vui lòng đăng nhập lại. Token có thể đã hết hạn.');
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }

  static Future<List<Event>> getMyEvents() async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/EventApi/my-events'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Event.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load my events: ${response.statusCode}');
    }
  }

  static Future<Event> getEventById(int id) async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/EventApi/$id'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load event: ${response.statusCode}');
    }
  }

  static Future<Event> addEvent(Event event) async {
    final eventJson = event.toJson();
    eventJson.remove('id'); // Không gửi id khi tạo mới
    
    final headers = await _buildHeaders();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/EventApi'),
        headers: headers,
        body: json.encode(eventJson),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền thực hiện thao tác này');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: API endpoint không tồn tại. Vui lòng kiểm tra lại kết nối.');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to add event: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }

  static Future<void> updateEvent(Event event) async {
    final headers = await _buildHeaders();
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/EventApi/${event.id}'),
        headers: headers,
        body: json.encode(event.toJson()),
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền thực hiện thao tác này');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: Sự kiện không tồn tại hoặc API endpoint không đúng');
      } else {
        throw Exception('Failed to update event: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }

  static Future<void> deleteEvent(int id) async {
    final headers = await _buildHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/EventApi/$id'),
      headers: headers,
    );
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete event: ${response.statusCode}');
    }
  }

  // EventCategory APIs
  static Future<List<EventCategory>> getEventCategories() async {
    final headers = await _buildHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/EventCategoryApi'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => EventCategory.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền truy cập');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: API endpoint không tồn tại. Vui lòng kiểm tra lại kết nối.');
      } else {
        throw Exception('Failed to load event categories: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }

  static Future<EventCategory> addEventCategory(EventCategory category) async {
    final categoryJson = category.toJson();
    categoryJson.remove('id');
    
    final headers = await _buildHeaders();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/EventCategoryApi'),
        headers: headers,
        body: json.encode(categoryJson),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return EventCategory.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền thực hiện thao tác này');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: API endpoint không tồn tại. Vui lòng kiểm tra lại kết nối.');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to add category: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }

  static Future<void> updateEventCategory(EventCategory category) async {
    final headers = await _buildHeaders();
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/EventCategoryApi/${category.id}'),
        headers: headers,
        body: json.encode(category.toJson()),
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền thực hiện thao tác này');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: Danh mục không tồn tại hoặc API endpoint không đúng');
      } else {
        throw Exception('Failed to update category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }

  static Future<void> deleteEventCategory(int id) async {
    final headers = await _buildHeaders();
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/EventCategoryApi/$id'),
        headers: headers,
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Vui lòng đăng nhập lại');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Bạn không có quyền thực hiện thao tác này');
      } else if (response.statusCode == 404) {
        throw Exception('Not Found: Danh mục không tồn tại hoặc API endpoint không đúng');
      } else {
        throw Exception('Failed to delete category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Lỗi kết nối: Không thể kết nối đến server. Vui lòng kiểm tra backend có đang chạy không.');
      }
      rethrow;
    }
  }
}

