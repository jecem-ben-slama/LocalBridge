import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/api_service.dart';
import '../../domain/services/phone_server.dart';
import '../../../../infrastructure/services/background_file_transfer_service.dart';

abstract interface class PhoneFilesRemoteSource {
  Future<void> connect();

  Future<void> disconnect();

  bool get isConnected;

  Future<bool> checkConnection();

  bool get isServerRunning;

  bool get isWebConnected;

  Stream<bool> get webConnectionChanges;

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
  bool _isConnected = false;

  PhoneFilesRemoteSourceImpl(
    this._apiService,
    this._phoneServer,
    this._backgroundTransfers,
  );

  @override
  bool get isWebConnected => _phoneServer.isPeerConnected;

  @override
  Stream<bool> get webConnectionChanges => _phoneServer.peerConnectionChanges;

  void _log(String message) {
    debugPrint('[PhoneFilesRemoteSource] $message');
  }

  @override
  Future<void> connect() async {
    _log('connect started; baseUrl=${_apiService.baseUrl}');
    await disconnect();
    _log('requesting storage access');
    await _requestStorageAccess();
    _rootDirectory = await _resolveRootDirectory();
    _log('storage root=${_rootDirectory!.path}');
    final response = await _apiService.dio.post('/api/phone/connect');
    _log('connect response status=${response.statusCode}');
    _isConnected = true;
    _log('legacy relay polling disabled; use the phone HTTP server');
  }

  @override
  Future<void> disconnect() async {
    await stopServer();
    _log('disconnect requested');
    _isConnected = false;
    try {
      final response = await _apiService.dio.post('/api/phone/disconnect');
      _log('disconnect response status=${response.statusCode}');
    } catch (error, stackTrace) {
      _log('disconnect request failed: $error\n$stackTrace');
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> checkConnection() async {
    try {
      final response = await _apiService.dio.get<Map<String, dynamic>>(
        '/api/phone/status',
      );
      final connected =
          response.statusCode == 200 && response.data?['connected'] == true;
      _isConnected = connected;
      return connected;
    } on DioException catch (error) {
      _log('connection check failed: ${error.message}');
      _isConnected = false;
      return false;
    }
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
    final uri = Uri.parse(_apiService.baseUrl).replace(
      path: '/api/files/upload',
      queryParameters: const {'path': 'LocalBridge'},
    );
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
