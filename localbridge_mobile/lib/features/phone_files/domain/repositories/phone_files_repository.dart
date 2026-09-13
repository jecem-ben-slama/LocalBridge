import 'dart:io';

import '../services/phone_server.dart';

abstract interface class PhoneFilesRepository {
  /// Stream that emits the current running state immediately upon subscription
  /// and updates in real-time whenever the server starts or stops.
  Stream<bool> get serverStatusStream;

  Future<PhoneServerInfo> startServer();

  Future<void> stopServer();

  Future<void> sendToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  });
}
