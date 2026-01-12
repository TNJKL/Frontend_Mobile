import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/menu.dart';
import '../Models/menu_item.dart';
import '../Models/global_menu_item.dart';
import '../config/config_url.dart';

class MenuApiService {
  static String get baseUrl => Config_URL.baseUrl;

  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Global catalog APIs
  static Future<List<GlobalMenuItem>> getGlobalItems() async {
    final headers = await _buildHeaders();
    final res = await http.get(Uri.parse('$baseUrl/GlobalMenuApi'), headers: headers);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => GlobalMenuItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load global items: ${res.statusCode}');
  }

  static Future<GlobalMenuItem> createGlobalItem(GlobalMenuItem item) async {
    final headers = await _buildHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/GlobalMenuApi'),
      headers: headers,
      body: json.encode(item.toJson()..remove('id')),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return GlobalMenuItem.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to create global item: ${res.statusCode} - ${res.body}');
  }

  static Future<void> updateGlobalItem(GlobalMenuItem item) async {
    final headers = await _buildHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/GlobalMenuApi/${item.id}'),
      headers: headers,
      body: json.encode(item.toJson()),
    );
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('Failed to update global item: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteGlobalItem(int id) async {
    final headers = await _buildHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/GlobalMenuApi/$id'), headers: headers);
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('Failed to delete global item: ${res.statusCode} - ${res.body}');
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

  static Future<List<Menu>> getMenusByEvent(int eventId) async {
    final headers = await _buildHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/MenuApi/by-event/$eventId'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => Menu.fromJson(e)).toList();
    }
    throw Exception('Failed to load menus: ${res.statusCode}');
  }

  static Future<Menu> getMenuById(int id) async {
    final headers = await _buildHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/MenuApi/$id'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return Menu.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to load menu: ${res.statusCode}');
  }

  static Future<Menu> createMenu(Menu menu) async {
    final headers = await _buildHeaders();
    final body = menu.toJson()..remove('id');
    final res = await http.post(
      Uri.parse('$baseUrl/MenuApi'),
      headers: headers,
      body: json.encode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return Menu.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to create menu: ${res.statusCode} - ${res.body}');
  }

  static Future<void> updateMenu(Menu menu) async {
    final headers = await _buildHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/MenuApi/${menu.id}'),
      headers: headers,
      body: json.encode(menu.toJson()),
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to update menu: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteMenu(int id) async {
    final headers = await _buildHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/MenuApi/$id'),
      headers: headers,
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to delete menu: ${res.statusCode}');
  }

  static Future<MenuItem> addItem(int menuId, MenuItem item) async {
    final headers = await _buildHeaders();
    final body = item.toJson()..remove('id');
    body['menuId'] = menuId;
    final res = await http.post(
      Uri.parse('$baseUrl/MenuApi/$menuId/items'),
      headers: headers,
      body: json.encode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return MenuItem.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to add item: ${res.statusCode} - ${res.body}');
  }

  static Future<MenuItem> getItem(int id) async {
    final headers = await _buildHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/MenuApi/items/$id'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return MenuItem.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to load item: ${res.statusCode}');
  }

  static Future<void> updateItem(MenuItem item) async {
    final headers = await _buildHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/MenuApi/items/${item.id}'),
      headers: headers,
      body: json.encode(item.toJson()),
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to update item: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteItem(int id) async {
    final headers = await _buildHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/MenuApi/items/$id'),
      headers: headers,
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to delete item: ${res.statusCode}');
  }

  static Future<void> placeOrder(int eventId, List<Map<String, dynamic>> items) async {
    final headers = await _buildHeaders();
    final body = json.encode({'items': items});
    final res = await http.post(
      Uri.parse('$baseUrl/MenuApi/$eventId/place-order'),
      headers: headers,
      body: body,
    );
    if (res.statusCode == 200) {
      return;
    }
    throw Exception('Failed to place order: ${res.statusCode} - ${res.body}');
  }

  static Future<Map<String, dynamic>> getOrders(int eventId) async {
    final headers = await _buildHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/MenuApi/$eventId/orders'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load orders: ${res.statusCode} - ${res.body}');
  }

  static Future<void> updateOrder(int eventId, int expenseId, int quantity) async {
    final headers = await _buildHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/MenuApi/$eventId/orders/$expenseId'),
      headers: headers,
      body: json.encode({'quantity': quantity}),
    );
    if (res.statusCode == 200) return;
    throw Exception('Failed to update order: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteOrder(int eventId, int expenseId) async {
    final headers = await _buildHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/MenuApi/$eventId/orders/$expenseId'),
      headers: headers,
    );
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('Failed to delete order: ${res.statusCode} - ${res.body}');
  }
}
