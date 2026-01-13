import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../Models/chat_message.dart';

class ChatService {
  HubConnection? _hubConnection;
  
  // Use Stream for broadcasting messages to both ChatScreen and Notification System
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Track if user is in ChatScreen to avoid spamming notifications
  bool isInChatScreen = false;

  Future<void> initConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) return;

    // BaseUrl ends with /api, but ChatHub is at root /chatHub
    // Remove /api from the end if present to get the root host
    final hostUrl = Config_URL.baseUrl.replaceAll("/api", "");
    final serverUrl = "$hostUrl/chatHub";
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => Future.value(token),
        ))
        .build();

    _hubConnection?.on("ReceiveMessage", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        String senderId = arguments[0].toString();
        String content = arguments[1].toString();
        DateTime timestamp = DateTime.now();
        if (arguments.length > 2) {
           timestamp = DateTime.tryParse(arguments[2].toString()) ?? DateTime.now();
        }

        // Broadcast to stream
        _messageController.add({
          'senderId': senderId,
          'content': content,
          'timestamp': timestamp,
        });
      }
    });

    try {
      await _hubConnection?.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  Future<void> sendMessage(String receiverId, String content) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("SendMessage", args: [receiverId, content]);
    } else {
        // Try reconnect?
         print("ChatService: Not connected to SignalR");
    }
  }

  Future<List<ChatMessage>> getHistory(String otherUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    
    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/ChatApi/History/$otherUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => ChatMessage.fromJson(item)).toList();
      }
    } catch (e) {
      print("GetHistory Error: $e");
    }
    return [];
  }

  Future<Map<String, String>?> getSupportInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/ChatApi/GetSupportInfo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'supportId': data['supportId'],
          'supportName': data['supportName']
        };
      }
    } catch (e) {
      print("GetSupportInfo Error: $e");
    }
    return null;
  }

  Future<List<dynamic>> getInbox() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    
    try {
      final response = await http.get(
        Uri.parse('${Config_URL.baseUrl}/ChatApi/Inbox'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("GetInbox Error: $e");
    }
    return [];
  }
  
  void dispose() {
    _hubConnection?.stop();
  }
}
