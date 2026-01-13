import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../Models/guest.dart';

class GuestQRScreen extends StatelessWidget {
  final Guest guest;

  const GuestQRScreen({super.key, required this.guest});

  @override
  Widget build(BuildContext context) {
    // Generate a simple QR data string: "CHECKIN_<ID>"
    // In production, encrypt this or use a signed token.
    final qrData = "CHECKIN_${guest.id}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Vé Mời Điện Tử"),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Xin chào xin mời, ${guest.fullName}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (guest.tableNumber != null)
                Text("Bàn số: ${guest.tableNumber}", style: const TextStyle(fontSize: 18, color: Colors.pink)),
              
              const SizedBox(height: 32),
              
              // Ticket Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
                  ],
                  border: Border.all(color: Colors.pink[100]!, width: 2),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250.0,
                      gapless: false,
                      foregroundColor: Colors.pink[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Đưa mã này cho nhân viên khi check-in",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
               const Text(
                "Chụp màn hình lại để lưu vé",
                style: TextStyle(fontSize: 16, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
