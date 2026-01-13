import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class AdminConversationListScreen extends StatefulWidget {
  const AdminConversationListScreen({super.key});

  @override
  State<AdminConversationListScreen> createState() => _AdminConversationListScreenState();
}

class _AdminConversationListScreenState extends State<AdminConversationListScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final data = await _chatService.getInbox();
    setState(() {
      _conversations = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn hỗ trợ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : _conversations.isEmpty
        ? const Center(child: Text("Chưa có tin nhắn nào", style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            itemCount: _conversations.length,
            itemBuilder: (context, index) {
              final conversation = _conversations[index];
              final userId = conversation['userId'];
              final userName = conversation['userName'] ?? 'Khách';
              final lastMessage = conversation['lastMessage'] ?? '';
              final timeStr = conversation['timestamp'];
              DateTime? time;
              if (timeStr != null) time = DateTime.tryParse(timeStr);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.pink[100],
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: TextStyle(color: Colors.pink[700])),
                ),
                title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  time != null ? DateFormat('HH:mm dd/MM').format(time) : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ChatScreen(receiverId: userId, receiverName: userName))
                  );
                },
              );
            },
          ),
    );
  }
}
