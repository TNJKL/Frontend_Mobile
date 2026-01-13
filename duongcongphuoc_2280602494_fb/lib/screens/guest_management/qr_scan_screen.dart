import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/guest_api_service.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final GuestApiService _apiService = GuestApiService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processCheckIn(barcode.rawValue!);
        break; 
      }
    }
  }

  Future<void> _processCheckIn(String qrData) async {
    setState(() => _isProcessing = true);
    
    // Format: CHECKIN_<ID>
    if (qrData.startsWith("CHECKIN_")) {
      try {
        final guestIdStr = qrData.split("_")[1];
        final guestId = int.tryParse(guestIdStr);
        
        if (guestId != null) {
          // Call API to check-in
          final guest = await _apiService.checkInGuest(guestId);
          _showResultDialog(true, "Check-in thành công!\nXin chào: ${guest.fullName}\nBàn: ${guest.tableNumber ?? 'Chưa xếp'}");
        } else {
           _showResultDialog(false, "Mã QR không hợp lệ (Lỗi ID)");
        }

      } catch (e) {
        _showResultDialog(false, "Lỗi xử lý mã: $e");
      }
    } else {
      _showResultDialog(false, "Mã QR không đúng định dạng của tiệc");
    }
  }

  void _showResultDialog(bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(success ? "Thành Công" : "Lỗi")
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(ctx);
               setState(() => _isProcessing = false); // Resume scanning
            },
            child: const Text("Tiếp tục quét"),
          )
        ],
      ),
    );
  }

  void _showManualInputDialog() {
     final controller = TextEditingController();
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text("Nhập mã thủ công"),
         content: TextField(
           controller: controller,
           decoration: const InputDecoration(
             labelText: "Nhập mã (VD: CHECKIN_123)",
             border: OutlineInputBorder()
           ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
           ElevatedButton(
             onPressed: () {
               Navigator.pop(ctx);
               if (controller.text.isNotEmpty) {
                 _processCheckIn(controller.text.trim());
               }
             },
             child: const Text("Xác nhận"),
           )
         ],
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Vé Mời'),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showManualInputDialog,
                icon: const Icon(Icons.keyboard),
                label: const Text("Nhập mã thủ công (Emulator)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
