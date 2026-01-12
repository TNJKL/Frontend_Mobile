import 'package:flutter/material.dart';
import '../services/user_api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await UserApiService.getUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRole(String userId, String currentRole) async {
    String? newRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Chọn vai trò mới'),
          children: ['Admin', 'Staff', 'User'].map((role) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  role,
                  style: TextStyle(
                    fontWeight: role == currentRole ? FontWeight.bold : FontWeight.normal,
                    color: role == currentRole ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (newRole != null && newRole != currentRole) {
      try {
        await UserApiService.updateUserRole(userId, newRole);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật vai trò thành công')),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật vai trò: $e')),
        );
      }
    }
  }

  Future<void> _toggleLock(String userId, bool isLocked) async {
    try {
      final result = await UserApiService.toggleUserLock(userId);
      bool newStatus = result['isLocked'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thay đổi trạng thái: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Lỗi: $_errorMessage'))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final roles = (user['roles'] as List<dynamic>).join(', ');
                      final isLocked = user['isLocked'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLocked ? Colors.grey : Colors.blue,
                            child: Text(
                              (user['initials'] ?? 'U').toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user['userName'] ?? 'Unknown',
                            style: TextStyle(
                              decoration: isLocked ? TextDecoration.lineThrough : null,
                              color: isLocked ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? ''),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roles.contains('Admin') ? Colors.red[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  roles,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roles.contains('Admin') ? Colors.red[800] : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Sửa vai trò',
                                onPressed: () => _updateRole(user['id'], roles),
                              ),
                              IconButton(
                                icon: Icon(
                                  isLocked ? Icons.lock : Icons.lock_open,
                                  color: isLocked ? Colors.red : Colors.green,
                                ),
                                tooltip: isLocked ? 'Mở khóa' : 'Khóa tài khoản',
                                onPressed: () => _toggleLock(user['id'], isLocked),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
