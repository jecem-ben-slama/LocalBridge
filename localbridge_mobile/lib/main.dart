import 'dart:io';

import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/qr_scanner_page.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }
  }
  await FileDownloader().start(autoCleanDatabase: true);
  FileDownloader().configureNotification(
    running: const TaskNotification(
      'LocalBridge • Working',
      'Uploading {filename}',
    ),
    complete: const TaskNotification(
      'LocalBridge • Complete',
      'Finished: {filename}',
    ),
    error: const TaskNotification(
      'LocalBridge • Failed',
      'Transfer failed: {filename}',
    ),
    progressBar: true,
  );
  setupDependencies();
  runApp(const LocalBridgeApp());
}

class LocalBridgeApp extends StatelessWidget {
  const LocalBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const QrScannerScreen(),
    );
  }
}
