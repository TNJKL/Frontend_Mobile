import 'dart:convert';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class Auth {
  static final AuthService _authService = AuthService();
  static final ApiClient _apiClient = ApiClient();

  // Đăng nhập
  static Future<Map<String, dynamic>> login(String username, String password) async {
    var result = await _authService.login(username, password);
    
    // AuthService đã trả về role trong result, không cần xử lý thêm
    return result; // returns a map with {success: bool, token: string?, role: string?, message: string?}
  }

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    return await _authService.loginWithGoogle(idToken);
  }

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String initials,
    required String role,
  }) async {
    // Tạo body để gửi lên API
    Map<String, dynamic> body = {
      "username": username,
      "email": email,
      "password": password,
      "initials": initials,
      "role": role,
    };

    // Gọi API đăng ký thông qua ApiClient
    try {
      var response = await _apiClient.post('/Authenticate/register', body: body);

      // Xử lý kết quả từ API
      if (response.statusCode == 200) {
        // Chuyển đổi body JSON từ API thành Map
        var result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'success': false,
          'message': 'Đăng ký thất bại, vui lòng thử lại.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    }
  }
}

