import 'package:flutter/material.dart';
import '../Models/vendor.dart';
import '../services/vendor_api_service.dart';

class VendorFormScreen extends StatefulWidget {
  final Vendor? vendor;

  const VendorFormScreen({super.key, this.vendor});

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Other';
  bool _isLoading = false;
  final VendorApiService _apiService = VendorApiService();

  final List<String> _vendorTypes = [
    'Restaurant', 'Decoration', 'Photography', 'Makeup', 'Attire', 'Music', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameController.text = widget.vendor!.name;
      _selectedType = widget.vendor!.vendorType;
      _contactController.text = widget.vendor!.contactPerson ?? '';
      _phoneController.text = widget.vendor!.phone ?? '';
      _emailController.text = widget.vendor!.email ?? '';
      _addressController.text = widget.vendor!.address ?? '';
      _notesController.text = widget.vendor!.notes ?? '';
    }
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final vendor = Vendor(
        id: widget.vendor?.id ?? 0,
        name: _nameController.text,
        vendorType: _selectedType,
        contactPerson: _contactController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        notes: _notesController.text,
      );

      if (widget.vendor == null) {
        await _apiService.createVendor(vendor);
      } else {
        await _apiService.updateVendor(vendor);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.vendor == null ? 'Thêm thành công' : 'Cập nhật thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendor == null ? 'Thêm Nhà cung cấp' : 'Sửa Nhà cung cấp'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên Nhà cung cấp *', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Loại hình dịch vụ', border: OutlineInputBorder()),
                items: _vendorTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Người liên hệ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVendor,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thông tin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
