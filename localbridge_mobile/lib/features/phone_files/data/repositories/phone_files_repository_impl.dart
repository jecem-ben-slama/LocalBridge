import 'dart:io';

import '../../domain/repositories/phone_files_repository.dart';
import '../datasources/phone_files_remote_source.dart';
import '../../domain/services/phone_server.dart';

class PhoneFilesRepositoryImpl implements PhoneFilesRepository {
  final PhoneFilesRemoteSource _remoteSource;

  PhoneFilesRepositoryImpl(this._remoteSource);

  @override
  Future<void> connect() => _remoteSource.connect();

  @override
  Future<void> disconnect() => _remoteSource.disconnect();

  @override
  bool get isConnected => _remoteSource.isConnected;

  @override
  Future<bool> checkConnection() => _remoteSource.checkConnection();

  @override
  bool get isServerRunning => _remoteSource.isServerRunning;

  @override
  bool get isWebConnected => _remoteSource.isWebConnected;

  @override
  Stream<bool> get webConnectionChanges => _remoteSource.webConnectionChanges;

  @override
  Future<PhoneServerInfo> startServer() => _remoteSource.startServer();

  @override
  Future<void> stopServer() => _remoteSource.stopServer();

  @override
  Future<void> sendToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _remoteSource.uploadToPc(file: file, onProgress: onProgress);
  }
}
