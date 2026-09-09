import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/connection/domain/repositories/connection_repository.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/navbar_page.dart';
import 'package:localbridge_mobile/injection_container.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  final TextEditingController _manualHostController = TextEditingController();
  final TextEditingController _manualCodeController = TextEditingController();

  Future<void> _handleQrScan(String scannedValue) async {
    if (_isConnecting) return;
    _isConnecting = true;
    if (mounted) setState(() => _isScanning = false);

    try {
      await locator<ConnectionRepository>().connectFromQr(scannedValue);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Navbar()),
        );
      }
    } catch (error) {
      if (mounted) {
        showAppFeedback(
          context,
          userMessage(error, fallback: 'Could not connect to LocalBridge.'),
          type: FeedbackType.error,
        );
      }
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _handleManualPairing() async {
    final rawInput = _manualCodeController.text.trim();

    try {
      await locator<ConnectionRepository>().connectWithCode(rawInput);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Navbar()),
        );
      }
    } catch (error) {
      if (mounted) {
        showAppFeedback(
          context,
          userMessage(error, fallback: 'Could not connect to LocalBridge.'),
          type: FeedbackType.error,
        );
      }
    }
  }

  void _showManualCodeDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111C2E),
          title: const Text(
            'Type pairing code',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: _manualCodeController,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Pairing code',
                hintText: 'AB12CD',
                filled: true,
                fillColor: const Color(0xFF1B2A40),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _handleManualPairing();
              },
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _manualHostController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Connect to PC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF111C2E),
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
                    _handleQrScan(barcode.rawValue!);
                    break;
                  }
                }
              },
            )
          : SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF162033), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.lightBlueAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.link_rounded,
                                  size: 38,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Pair your phone with the web app',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scan the QR code from the PC or enter the pairing code manually.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        FilledButton.icon(
                          onPressed: () => setState(() => _isScanning = true),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scan QR code'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _showManualCodeDialog,
                          icon: const Icon(Icons.keyboard_rounded),
                          label: const Text('Type code'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
