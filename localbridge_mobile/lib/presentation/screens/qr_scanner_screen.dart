import 'package:flutter/material.dart';
import 'package:localbridge_mobile/data/services/api_services.dart';
import 'package:localbridge_mobile/presentation/screens/dashboard_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // State variable to track if the camera should be active
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Scan PC QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        // Allows the user to cancel scanning and go back to the button view
        leading: _isScanning
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _isScanning = false),
              )
            : const BackButton(color: Colors.white),
      ),
      body: _isScanning
          ? MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    final scannedUrl = barcode.rawValue!;
                    ApiService.baseUrl = scannedUrl;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                    break;
                  }
                }
              },
            )
          : Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  'Start Scanner',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () {
                  // Update state to show the scanner
                  setState(() {
                    _isScanning = true;
                  });
                },
              ),
            ),
    );
  }
}
