import 'dart:async';
import 'dart:io';

import '../../domain/repositories/phone_files_repository.dart';
import '../../domain/services/phone_server.dart';
import '../datasources/phone_files_remote_source.dart';

class PhoneFilesRepositoryImpl implements PhoneFilesRepository {
  final PhoneFilesRemoteSource _remoteSource;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  PhoneFilesRepositoryImpl(this._remoteSource);

  @override

  @override
  Stream<bool> get serverStatusStream => _statusController.stream;

  @override
  Future<PhoneServerInfo> startServer() async {
    final info = await _remoteSource.startServer();
    _statusController.add(true);
    return info;
  }

  @override
  Future<void> stopServer() async {
    await _remoteSource.stopServer();
    _statusController.add(false);
  }

  @override
  Future<void> sendToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _remoteSource.uploadToPc(file: file, onProgress: onProgress);
  }
}
