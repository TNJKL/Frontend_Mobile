import 'package:flutter/material.dart';
import '../Models/vendor.dart';

class VendorDetailScreen extends StatelessWidget {
  final Vendor vendor;
  final bool isSelecting; // If true, show "Select" button

  const VendorDetailScreen({
    super.key,
    required this.vendor,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.store, size: 80, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.indigo[50],
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.indigo[100]!),
                         ),
                         child: Text(vendor.vendorType, style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.bold)),
                       ),
                       const Spacer(),
                       // Rating or other badges could go here
                     ],
                   ),
                   const SizedBox(height: 16),
                   Text(
                     vendor.name,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   if (vendor.address != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(vendor.address!, style: const TextStyle(color: Colors.grey))),
                      ],
                    ),

                   const Divider(height: 32),

                   const Text("Giới thiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text(
                     vendor.notes?.isNotEmpty == true ? vendor.notes! : "Chưa có mô tả chi tiết.",
                     style: const TextStyle(height: 1.5, fontSize: 15),
                   ),

                   const Divider(height: 32),

                   const Text("Thông tin liên hệ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   if (vendor.contactPerson != null)
                     _buildInfoRow(Icons.person, "Người liên hệ", vendor.contactPerson!),
                   if (vendor.phone != null)
                     _buildInfoRow(Icons.phone, "Điện thoại", vendor.phone!),
                   if (vendor.email != null)
                     _buildInfoRow(Icons.email, "Email", vendor.email!),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isSelecting
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, vendor); // Return vendor to select
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Chọn Nhà Cung Cấp Này", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
