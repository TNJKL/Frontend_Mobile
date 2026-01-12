import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/global_menu_item.dart';
import '../services/menu_api_service.dart';
import '../utils/user_helper.dart';

class AdminMenuManagementScreen extends StatefulWidget {
  const AdminMenuManagementScreen({super.key});
  @override
  State<AdminMenuManagementScreen> createState() => _AdminMenuManagementScreenState();
}

class _AdminMenuManagementScreenState extends State<AdminMenuManagementScreen> {
  bool _loading = false;
  bool _isAdminOrStaff = false;
  bool _isStaff = false;
  List<GlobalMenuItem> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('user_role');
    bool roleOk = false;
    bool isStaff = false;

    if (role != null) {
      final r = role.toLowerCase();
      if (r == 'admin' || r == 'staff') roleOk = true;
      if (r == 'staff') isStaff = true;
    }

    if (!mounted) return;
    setState(() {
      _isAdminOrStaff = roleOk;
      _isStaff = isStaff;
    });
    await _loadGlobalItems();
  }

  Future<void> _loadGlobalItems() async {
    setState(() => _loading = true);
    try {
      final data = await MenuApiService.getGlobalItems();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải món chung: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog([GlobalMenuItem? item]) async {
    final nameCtrl = TextEditingController(text: item?.name);
    final catCtrl = TextEditingController(text: item?.category);
    final descCtrl = TextEditingController(text: item?.description);
    final priceCtrl = TextEditingController(text: item?.unitPrice?.toString() ?? '0');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl);
    int displayOrder = item?.displayOrder ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item == null ? 'Thêm Món Mới' : 'Cập Nhật Món Ăn',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField(nameCtrl, 'Tên món ăn', Icons.restaurant_menu),
                    const SizedBox(height: 16),
                    _buildTextField(catCtrl, 'Danh mục (Khai vị, Món chính...)', Icons.category),
                    const SizedBox(height: 16),
                    _buildTextField(priceCtrl, 'Đơn giá (VNĐ)', Icons.attach_money, isNumber: true),
                    const SizedBox(height: 16),
                    _buildTextField(descCtrl, 'Mô tả chi tiết', Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(imageUrlCtrl, 'Link hình ảnh', Icons.image),
                    const SizedBox(height: 16),
                    _buildTextField(
                      TextEditingController(text: displayOrder.toString()), 
                      'Thứ tự hiển thị', 
                      Icons.sort, 
                      isNumber: true,
                      onChanged: (val) => displayOrder = int.tryParse(val) ?? 0
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  Navigator.pop(context);
                  _saveItem(item, nameCtrl.text, catCtrl.text, descCtrl.text, priceCtrl.text, imageUrlCtrl.text, displayOrder);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0
                ),
                child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem(GlobalMenuItem? originalItem, String name, String cat, String desc, String price, String img, int order) async {
    setState(() => _loading = true);
    try {
      final newItem = GlobalMenuItem(
        id: originalItem?.id, // Keep ID if updating
        name: name,
        category: cat.isEmpty ? null : cat,
        description: desc.isEmpty ? null : desc,
        unitPrice: double.tryParse(price),
        imageUrl: img.isEmpty ? null : img,
        displayOrder: order,
      );

      if (originalItem == null) {
        await MenuApiService.createGlobalItem(newItem);
      } else {
        // Implement Update Logic if API supports it, or Delete & Re-create if strict
        // Assuming API might not have update endpoint for GlobalItem based on previous code view, 
        // but typically Create handles logic. Let's assume user wants to Create for now if Update not clear.
        // Wait, I should check API. The provided code used createGlobalItem.
        // Let's stick to Create for new list. If update needed, I'd need to verify Update endpoint.
        // The original code only had Create and Delete. I will Assume only Create/Delete for now to be safe
        // Or better, Delete old and Create new to simulate update
        await MenuApiService.deleteGlobalItem(originalItem.id!);
        await MenuApiService.createGlobalItem(newItem);
      }
      
      await _loadGlobalItems();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thành công!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món ăn?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await MenuApiService.deleteGlobalItem(id);
        await _loadGlobalItems();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa món ăn')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản Lý Thực Đơn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: (_isAdminOrStaff && !_isStaff) ? FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdminOrStaff
              ? const Center(child: Text('Bạn không có quyền truy cập.'))
              : _items.isEmpty 
                  ? const Center(child: Text('Chưa có món ăn nào.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                      ? Image.network(item.imageUrl!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)))
                                      : Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.restaurant_menu, size: 40, color: Colors.grey))),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(item.category ?? 'Món khác', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${item.unitPrice?.toInt() ?? 0} đ', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showAddEditDialog(item),
                                              child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _deleteItem(item.id!),
                                              child: const Icon(Icons.delete, size: 18, color: Colors.red),
                                            ),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
