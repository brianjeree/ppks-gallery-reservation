import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Pause/Stop camera to prevent multiple scans
    await _controller.stop();

    // Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Update Firestore document
      // Check if document exists first to provide better error message? 
      // User asked to update status to 'completed'. 
      // We will try to update directly.
      
      final docRef = FirebaseFirestore.instance.collection('reservations').doc(code);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception("Tiket tidak ditemukan");
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'];

      if (currentStatus == 'completed') {
         // Already checked in
         if (!mounted) return;
         Navigator.pop(context); // Close loading
         _showResultDialog("Tiket ini sudah Check-in sebelumnya.");
         return;
      }
      
      if (currentStatus != 'approved') {
         // Only approved tickets can check in
         if (!mounted) return;
         Navigator.pop(context); // Close loading
         _showError("Tiket status: $currentStatus. Belum disetujui admin.");
         return;
      }

      await docRef.update({'status': 'completed'});

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog();

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Check-in Berhasil!'),
        content: const Text('Pengunjung dipersilakan masuk.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Back to Dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String message) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info, color: Colors.orange, size: 60),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              _resumeCamera();
             },
            child: const Text('Scan Lagi'),
          ),
          TextButton(
            onPressed: () {
               Navigator.pop(context);
               Navigator.pop(context); // Exit
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    _resumeCamera(); // Resume scanning if error
  }

  void _resumeCamera() {
     setState(() {
      _isProcessing = false;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleScan,
          ),
          // Overlay UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                       /* 
                       // Flash toggling commented out due to API uncertainty
                       CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          onPressed: () => _controller.toggleTorch(),
                        ),
                      ),
                      */
                    ],
                   ),
                   const Spacer(),
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text(
                       "Arahkan kamera ke QR Code",
                       style: TextStyle(color: Colors.white, fontSize: 16),
                     ),
                   ),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
