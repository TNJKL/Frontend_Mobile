import 'package:flutter/material.dart';
import '../Models/service_package.dart';
import '../Models/service_package_item.dart';
import '../Models/global_menu_item.dart';
import '../services/service_package_api_service.dart';
import '../services/menu_api_service.dart';
import 'package:intl/intl.dart';

class AdminServicePackageDetailScreen extends StatefulWidget {
  final ServicePackage? package;

  const AdminServicePackageDetailScreen({super.key, this.package});

  @override
  _AdminServicePackageDetailScreenState createState() => _AdminServicePackageDetailScreenState();
}

class _AdminServicePackageDetailScreenState extends State<AdminServicePackageDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  List<ServicePackageItem> _items = [];
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _descController = TextEditingController(text: widget.package?.description ?? '');
    _priceController = TextEditingController(text: widget.package?.price.toString() ?? '0');
    _imageController = TextEditingController(text: widget.package?.imageUrl ?? '');
    _isActive = widget.package?.isActive ?? true;
    
    if (widget.package != null) {
      _items = List.from(widget.package!.servicePackageItems);
    }
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất một mục vào gói.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pkg = ServicePackage(
        id: widget.package?.id ?? 0,
        name: _nameController.text,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        imageUrl: _imageController.text,
        isActive: _isActive,
        servicePackageItems: _items,
      );

      if (widget.package == null) {
        await ServicePackageApiService.createServicePackage(pkg);
      } else {
        await ServicePackageApiService.updateServicePackage(pkg);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recalculatePrice() {
    double total = _items.fold(0, (sum, item) => sum + item.customValue);
    _priceController.text = total.toStringAsFixed(0);
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddItemSheet(onAdd: (item) {
        setState(() {
          _items.add(item);
          _recalculatePrice();
        });
        Navigator.pop(ctx);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package == null ? 'Tạo Gói Mới' : 'Cập Nhật Gói'),
        backgroundColor: Colors.pink[50], // Consistent theme
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _savePackage,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên Gói', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Nhập tên gói' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Giá Trọn Gói (VNĐ)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Nhập giá' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                        const Text('Kích hoạt'),
                      ],
                    ),
                     const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(labelText: 'URL Ảnh (Tùy chọn)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Danh sách mục (Items)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showAddItemSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Mục'),
                        )
                      ],
                    ),
                    const Divider(),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('Chưa có mục nào được chọn', style: TextStyle(color: Colors.grey))),
                      ),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(item.itemType == 'Food' ? Icons.restaurant : Icons.room_service, color: Colors.pink[300]),
                              title: Text(item.customName ?? 'Dịch vụ'),
                              subtitle: Text('Giá trị: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(item.customValue)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                    _recalculatePrice();
                                  });
                                },
                              ),
                            ),
                          );
                    }).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final Function(ServicePackageItem) onAdd;

  const _AddItemSheet({required this.onAdd});

  @override
  __AddItemSheetState createState() => __AddItemSheetState();
}

class __AddItemSheetState extends State<_AddItemSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GlobalMenuItem> _globalItems = [];
  bool _isLoading = true;
  
  // Custom Service Form
  final _customNameController = TextEditingController();
  final _customPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGlobalItems();
  }

  Future<void> _loadGlobalItems() async {
    try {
      final items = await MenuApiService.getGlobalItems(); // Assuming this API exists
      setState(() {
        _globalItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false); // Handle error silently or show toast
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: 'Chọn Món Ăn'), Tab(text: 'Dịch Vụ Khác')],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Food Tab
                _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _globalItems.length,
                        itemBuilder: (ctx, i) {
                          final item = _globalItems[i];
                          return ListTile(
                            leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.fastfood, size: 40, color: Colors.orange),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(item.unitPrice)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                widget.onAdd(ServicePackageItem(
                                  id: 0,
                                  servicePackageId: 0,
                                  itemType: 'Food',
                                  referenceId: item.id,
                                  customName: item.name, // Store name locally for display if needed, but backend uses ID
                                  customValue: item.unitPrice?.toDouble() ?? 0,
                                ));
                              },
                            ),
                          );
                        },
                      ),
                // Custom Service Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _customNameController,
                        decoration: const InputDecoration(labelText: 'Tên Dịch Vụ', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customPriceController,
                        decoration: const InputDecoration(labelText: 'Giá Trị (VNĐ)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_customNameController.text.isNotEmpty && _customPriceController.text.isNotEmpty) {
                             widget.onAdd(ServicePackageItem(
                                  id: 0,
                                  servicePackageId: 0,
                                  itemType: 'Service',
                                  customName: _customNameController.text,
                                  customValue: double.tryParse(_customPriceController.text) ?? 0,
                                ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                        child: const Text('Thêm Dịch Vụ'),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
