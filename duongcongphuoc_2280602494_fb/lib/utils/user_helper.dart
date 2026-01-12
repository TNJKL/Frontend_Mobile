import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserHelper {
  /// Lấy userId từ JWT token
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return null;
      
      final decodedToken = JwtDecoder.decode(token);
      
      // Thử các claim phổ biến cho userId
      return decodedToken['sub'] ?? 
             decodedToken['nameid'] ?? 
             decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
             decodedToken['userId'] ??
             decodedToken['UserId'];
    } catch (e) {
      return null;
    }
  }
  
  /// Lấy user role từ SharedPreferences
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'User';
  }
  
  /// Kiểm tra xem user có phải Admin hoặc Staff không
  static Future<bool> isAdminOrStaff() async {
    final role = await getUserRole();
    return role.toLowerCase() == 'admin' || role.toLowerCase() == 'staff';
  }
  
  /// Kiểm tra xem user có thể chỉnh sửa event không
  /// - Admin/Staff: có thể sửa tất cả
  /// - User: chỉ có thể sửa event của chính họ
  static Future<bool> canEditEvent(String? eventUserId) async {
    if (await isAdminOrStaff()) {
      return true; // Admin/Staff có thể sửa tất cả
    }
    
    // User chỉ có thể sửa event của chính họ
    final currentUserId = await getUserId();
    return currentUserId != null && currentUserId == eventUserId;
  }
}





