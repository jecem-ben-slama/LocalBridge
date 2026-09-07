import 'package:flutter/material.dart';
import 'presentation/screens/qr_scanner_screen.dart';

void main() {
  runApp(const LocalBridgeApp());
}

class LocalBridgeApp extends StatelessWidget {
  const LocalBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark, // Matches our dark slate UI design theme
        ),
        useMaterial3: true,
      ),
      // Start the application by scanning the PC connection QR code
      home: const QrScannerScreen(),
    );
  }
}
