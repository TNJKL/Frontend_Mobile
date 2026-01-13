import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../Models/chat_message.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  String _currentUserId = "";
  bool _isLoading = true;

  late StreamSubscription _messageSubscription;

  @override
  void initState() {
    super.initState();
    _chatService.isInChatScreen = true;
    _initChat();
  }
  
  void _initChat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    if (token != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      _currentUserId = decodedToken['id'] ?? decodedToken['sub'] ?? '';
      if (_currentUserId.isEmpty) {
        _currentUserId = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '';
      }
    }

    await _chatService.initConnection();
    
    // Listen to the broadcast stream
    _messageSubscription = _chatService.messageStream.listen((data) {
       String senderId = data['senderId'];
       String content = data['content'];
       DateTime timestamp = data['timestamp'];

       if (senderId == widget.receiverId || senderId == _currentUserId) {
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                id: 0, 
                senderId: senderId, 
                receiverId: senderId == _currentUserId ? widget.receiverId : _currentUserId, 
                content: content, 
                timestamp: timestamp, 
                isRead: true
              ));
            });
            _scrollToBottom();
          }
       }
    });

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _chatService.getHistory(widget.receiverId);
      if (mounted) {
        setState(() {
          _messages = history;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a slight delay to ensure list is rendered
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text;
    
    _chatService.sendMessage(widget.receiverId, content);
    
    // Optimistic UI update
    // setState(() {
    //   _messages.add(ChatMessage(
    //     id: 0, 
    //     senderId: _currentUserId, 
    //     receiverId: widget.receiverId, 
    //     content: content, 
    //     timestamp: DateTime.now(), 
    //     isRead: false
    //   ));
    // });
    
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatService.isInChatScreen = false;
    _messageSubscription.cancel();
    _chatService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(child: Text(widget.receiverName.isNotEmpty ? widget.receiverName[0] : "?")),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                const Text("Online", style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            )
          ],
        ),
        backgroundColor: Colors.pink[400],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg.senderId == _currentUserId;
                  return alignMessage(isMe, msg);
                },
              ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget alignMessage(bool isMe, ChatMessage msg) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink[400] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black45,
                fontSize: 10
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), offset: const Offset(0, -2), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.pink[400],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }
}
