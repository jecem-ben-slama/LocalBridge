import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/api_service.dart';
import '../../domain/services/phone_server.dart';
import '../../../../infrastructure/services/background_file_transfer_service.dart';

abstract interface class PhoneFilesRemoteSource {
  bool get isServerRunning;

  Future<PhoneServerInfo> startServer();

  Future<void> stopServer();

  Future<void> uploadToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  });
}

class PhoneFilesRemoteSourceImpl implements PhoneFilesRemoteSource {
  final ApiService _apiService;
  final PhoneServer _phoneServer;
  final BackgroundFileTransferService _backgroundTransfers;
  Directory? _rootDirectory;

  PhoneFilesRemoteSourceImpl(
    this._apiService,
    this._phoneServer,
    this._backgroundTransfers,
  );

  void _log(String message) {
    debugPrint('[PhoneFilesRemoteSource] $message');
  }

  @override
  bool get isServerRunning => _phoneServer.isRunning;

  @override
  Future<PhoneServerInfo> startServer() async {
    if (_rootDirectory == null) {
      await _requestStorageAccess();
      _rootDirectory = await _resolveRootDirectory();
    }
    final token = _apiService.authToken;
    if (token == null || token.isEmpty) {
      throw StateError('The LocalBridge session token is missing.');
    }
    final info = await _phoneServer.start(
      rootDirectory: _rootDirectory!,
      authToken: token,
    );
    try {
      await _apiService.dio.post(
        '/api/phone/server',
        data: {'url': info.baseUrl, 'token': token},
      );
      _log('phone server registered: ${info.baseUrl}');
      return info;
    } catch (_) {
      await _phoneServer.stop();
      rethrow;
    }
  }

  @override
  Future<void> stopServer() async {
    if (!_phoneServer.isRunning) return;
    try {
      await _apiService.dio.delete('/api/phone/server');
    } catch (error) {
      _log('phone server unregister failed: $error');
    } finally {
      await _phoneServer.stop();
    }
  }

  @override
  Future<void> uploadToPc({
    required File file,
    required void Function(int sent, int total) onProgress,
  }) async {
    // NOTE: this must hit PhoneFileController's dedicated endpoint
    // (/api/phone/upload), not FileController's /api/files/upload.
    // The latter resolves `path` against the general PC-browsing root
    // and does not create missing directories, so a phone push to a
    // not-yet-existing "LocalBridge" folder there fails. The phone
    // endpoint resolves against `uploadedPhoneRoot` and calls
    // Files.createDirectories(...) before writing, and defaults to
    // that root when no `path` is supplied.
    final uri = Uri.parse(
      _apiService.baseUrl,
    ).replace(path: '/api/phone/upload');
    await _backgroundTransfers.upload(
      url: uri,
      file: file,
      headers: _apiService.headers,
      fields: const {},
      onProgress: onProgress,
    );
  }

  Future<Directory> _resolveRootDirectory() async {
    if (Platform.isAndroid) {
      final sharedStorage = Directory('/storage/emulated/0');
      if (await sharedStorage.exists()) {
        _log('using Android shared storage root');
        return sharedStorage;
      }
    }
    _log('using application documents directory root');
    return getApplicationDocumentsDirectory();
  }

  Future<void> _requestStorageAccess() async {
    if (!Platform.isAndroid) {
      _log('storage permission skipped on ${Platform.operatingSystem}');
      return;
    }
    final status = await Permission.manageExternalStorage.request();
    _log('storage permission status=$status');
    if (!status.isGranted) {
      throw StateError(
        'Storage access is required to browse phone files from the PC.',
      );
    }
  }
}
