import 'package:flutter/material.dart';
import '../Models/service_package.dart';
import '../services/service_package_api_service.dart';
import 'package:intl/intl.dart';
import 'admin_service_package_detail_screen.dart';

class AdminServicePackageManagementScreen extends StatefulWidget {
  const AdminServicePackageManagementScreen({super.key});

  @override
  _AdminServicePackageManagementScreenState createState() => _AdminServicePackageManagementScreenState();
}

class _AdminServicePackageManagementScreenState extends State<AdminServicePackageManagementScreen> {
  List<ServicePackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await ServicePackageApiService.getServicePackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải gói dịch vụ: $e')));
    }
  }

  Future<void> _deletePackage(int id) async {
    if (!await _showConfirmation('Xóa gói dịch vụ', 'Bạn có chắc chắn muốn xóa gói này?')) return;
    
    try {
      await ServicePackageApiService.deleteServicePackage(id);
      _loadPackages();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa gói dịch vụ')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
    }
  }

  Future<bool> _showConfirmation(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showPackageDialog([ServicePackage? package]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminServicePackageDetailScreen(package: package)),
    );
    
    if (result == true) {
      _loadPackages();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu gói dịch vụ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Gói Dịch Vụ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final pkg = _packages[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showPackageDialog(pkg), 
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5, // Increase image ratio slightly (was 3:2, now 5:4)
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                image: pkg.imageUrl != null && pkg.imageUrl!.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(pkg.imageUrl!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: pkg.imageUrl == null || pkg.imageUrl!.isEmpty
                                  ? Icon(Icons.inventory_2, size: 40, color: Colors.pink[200])
                                  : null,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0), // Reduced from 12.0
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2, // Allow 2 lines
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(locale: 'vi', symbol: 'đ').format(pkg.price),
                                    style: TextStyle(color: Colors.pink[700], fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                       Text('${pkg.servicePackageItems.length} mục', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                       IconButton(
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(),
                                         icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), // Smaller icon
                                         onPressed: () => _deletePackage(pkg.id),
                                       ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageDialog(),
        label: const Text('Tạo Gói Mới'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.pink[400],
      ),
    );
  }
}
