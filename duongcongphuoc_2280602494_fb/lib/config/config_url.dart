import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:io';

class Config_URL {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url != null && url.isNotEmpty) return url;

    if (Platform.isAndroid) {
      return "http://192.168.88.138:5226/api";
    }
    
    return "http://localhost:5226/api";
  }
}
