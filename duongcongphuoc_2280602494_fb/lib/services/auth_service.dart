import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class AuthService {
  // đường dẫn tới API login
  String get apiUrl => "${Config_URL.baseUrl}/Authenticate/login";

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        //Lấy thông tin tên đăng nhập và password
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'];
        if (!status) {
          return {"success": false, "message": data['message']};
        }
        //lấy token trả về
        String token = data['token'];
        // Decode token để lấy các thông tin đăng nhập: tên đăng nhập, role...
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        // Lưu token và role vào SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token); // Lưu token

        // Lưu role từ decodedToken
        String role =
            decodedToken['role'] ??
            decodedToken['Role'] ??
            decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
            'User';
        prefs.setString('user_role', role); // Lưu role

        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
          "role": role,
        };
      } else {
        // If status code is not 200, treat it as login failure
        return {
          "success": false,
          "message": "Failed to login: ${response.statusCode}",
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      return {"success": false, "message": "Network error: $e"};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse("${Config_URL.baseUrl}/Authenticate/login-google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'];
        if (!status) {
          return {"success": false, "message": data['message']};
        }

        String token = data['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token);

        String role =
            decodedToken['role'] ??
            decodedToken['Role'] ??
            decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
            'User';
        prefs.setString('user_role', role);

        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
          "role": role,
        };
      } else {
        return {
          "success": false,
          "message": "Failed to login with Google: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
