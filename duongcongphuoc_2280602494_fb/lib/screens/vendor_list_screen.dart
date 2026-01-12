import 'package:flutter/material.dart';
import '../Models/vendor.dart';
import '../services/vendor_api_service.dart';
import 'vendor_form_screen.dart';
import 'vendor_contracts_screen.dart';
import 'vendor_detail_screen.dart';
import '../utils/user_helper.dart';

class VendorListScreen extends StatefulWidget {
  final bool isSelecting;
  const VendorListScreen({super.key, this.isSelecting = false});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final VendorApiService _apiService = VendorApiService();
  List<Vendor> _vendors = [];
  List<Vendor> _filteredVendors = [];
  bool _isLoading = true;
  String _userRole = 'User';
  String _searchQuery = '';
  String? _selectedType;

  final List<String> _vendorTypes = [
    'Restaurant', 'Decoration', 'Photography', 'Makeup', 'Attire', 'Music', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadVendors();
  }

  Future<void> _loadUserRole() async {
    final role = await UserHelper.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final vendors = await _apiService.getVendors();
      setState(() {
        _vendors = vendors;
        _filterVendors();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _vendors.where((v) {
        final matchSearch = v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (v.vendorType.toLowerCase().contains(_searchQuery.toLowerCase()));
        final matchType = _selectedType == null || v.vendorType == _selectedType;
        return matchSearch && matchType;
      }).toList();
    });
  }

  Future<void> _deleteVendor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa nhà cung cấp này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteVendor(id);
      _loadVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Chọn Nhà Cung Cấp' : 'Danh bạ Nhà cung cấp', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterVendors();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text('Loại hình'),
                  value: _selectedType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ..._vendorTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                    _filterVendors();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                    ? const Center(child: Text('Không tìm thấy nhà cung cấp nào.'))
                    : ListView.builder(
                        itemCount: _filteredVendors.length,
                        itemBuilder: (context, index) {
                          final vendor = _filteredVendors[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo[100],
                                child: Icon(_getIconForType(vendor.vendorType), color: Colors.indigo),
                              ),
                              title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${vendor.vendorType} • ${vendor.phone ?? 'No Phone'}'),
                              trailing: (widget.isSelecting)
                                  ? const Icon(Icons.check_circle_outline, color: Colors.green)
                                  : (_userRole == 'Admin')
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () async {
                                                 final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => VendorFormScreen(vendor: vendor)),
                                                );
                                                if (result == true) _loadVendors();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteVendor(vendor.id),
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.chevron_right),
                              onTap: () async {
                                if (widget.isSelecting) {
                                  // Open Detail Screen to let user review before selecting
                                  final selectedVendor = await Navigator.push<Vendor>(
                                    context,
                                    MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor, isSelecting: true)),
                                  );
                                  
                                  if (selectedVendor != null && context.mounted) {
                                    Navigator.pop(context, selectedVendor);
                                  }
                                } else if (_userRole == 'Admin' || _userRole == 'Staff') {
                                   await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VendorContractsScreen(vendor: vendor)),
                                  );
                                } else {
                                  // Normal user viewing list (if accessed via future features)
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor, isSelecting: false)),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: (!widget.isSelecting && _userRole == 'Admin')
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorFormScreen()),
                );
                if (result == true) _loadVendors();
              },
            )
          : null,
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Restaurant': return Icons.restaurant;
      case 'Decoration': return Icons.celebration;
      case 'Photography': return Icons.camera_alt;
      case 'Makeup': return Icons.face;
      case 'Attire': return Icons.checkroom;
      case 'Music': return Icons.music_note;
      default: return Icons.store;
    }
  }
}
