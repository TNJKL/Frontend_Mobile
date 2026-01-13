import 'package:flutter/material.dart';
import '../Models/service_package.dart';
import '../services/service_package_api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServicePackageSelectionScreen extends StatefulWidget {
  final int eventId;

  const ServicePackageSelectionScreen({super.key, required this.eventId});

  @override
  _ServicePackageSelectionScreenState createState() => _ServicePackageSelectionScreenState();
}

class _ServicePackageSelectionScreenState extends State<ServicePackageSelectionScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải gói: $e')));
    }
  }

  Future<void> _applyPackage(ServicePackage pkg) async {
    // 1. Get Table Count
    final prefs = await SharedPreferences.getInstance();
    int tableCount = prefs.getInt('table_count_${widget.eventId}') ?? 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chọn gói ${pkg.name}?'),
        content: Text('Hệ thống sẽ áp dụng gói này cho $tableCount bàn.\n(Giá Food x $tableCount + Giá Dịch vụ)\n\nBạn có thể chỉnh số bàn trong phần Thực Đơn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ServicePackageApiService.applyPackageToEvent(pkg.id, widget.eventId, tableCount: tableCount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã áp dụng gói thành công!')));
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi áp dụng gói: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPackageDetail(ServicePackage pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pkg.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 8),
              Text(pkg.description ?? '', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
              const Divider(),
              const Text('Chi tiết gói:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...pkg.servicePackageItems.map((item) => ListTile(
                dense: true,
                leading: Icon(item.itemType == 'Food' ? Icons.restaurant : Icons.room_service, color: Colors.orange),
                title: Text(item.customName ?? 'Dịch vụ'),
                trailing: Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(item.customValue)),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng giá trị:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(locale: 'vi', symbol: 'đ').format(pkg.price),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyPackage(pkg);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  child: const Text('Chọn Gói Này'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Gói Dịch Vụ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final pkg = _packages[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showPackageDetail(pkg),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
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
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pkg.description ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    NumberFormat.currency(locale: 'vi', symbol: 'đ').format(pkg.price),
                                    style: TextStyle(color: Colors.pink[700], fontWeight: FontWeight.bold),
                                  ),
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
    );
  }
}
