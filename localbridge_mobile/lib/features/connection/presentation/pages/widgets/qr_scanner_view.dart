import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatelessWidget {
    final ValueChanged<String> onScanComplete;

  const QrScannerView({super.key, required this.onScanComplete});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            onScanComplete(barcode.rawValue!);
            break;
          }
        }
      },
    );
  }
}