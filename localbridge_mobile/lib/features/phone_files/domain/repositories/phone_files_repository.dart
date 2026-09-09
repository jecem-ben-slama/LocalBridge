import 'dart:io';

import '../services/phone_server.dart';

abstract interface class PhoneFilesRepository {
  Future<void> connect();

  Future<void> disconnect();

  bool get isConnected;

  Future<bool> checkConnection();

  bool get isServerRunning;

  bool get isWebConnected;

  Stream<bool> get webConnectionChanges;

  Future<PhoneServerInfo> startServer();

  Future<void> stopServer();

  Future<void> sendToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  });
}
