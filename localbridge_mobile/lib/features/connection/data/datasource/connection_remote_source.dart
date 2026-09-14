import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:localbridge_mobile/core/services/session_service.dart';

import '../../../../core/network/api_service.dart';
import '../../../phone_files/domain/services/phone_server.dart';

abstract interface class ConnectionRemoteSource {
  Future<void> connect();

  Future<void> disconnect();

  bool get isConnected;

  Future<bool> checkConnection();

  bool get isWebConnected;

  Stream<bool> get webConnectionChanges;

  Stream<bool> get pcConnectionChanges;

  void dispose();
}

class ConnectionRemoteSourceImpl implements ConnectionRemoteSource {
  final ApiService _apiService;
  final PhoneServer _phoneServer;
  final SessionService _sessionService;

  bool _isConnected = false;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _shouldBeConnected = false;

  final _pcConnectionController = StreamController<bool>.broadcast();

  ConnectionRemoteSourceImpl(
    this._apiService,
    this._phoneServer,
    this._sessionService,
  ) {
    // If the backend tells us (via heartbeat) that our session has expired
    // server-side - e.g. it idle-disconnected us after X minutes - treat
    // that the same as any other disconnect: stop the local phone server,
    // clear session state, and update connection status. Without this the
    // phone kept heartbeating (and serving files) a session the backend
    // had already forgotten about.
    _sessionService.onSessionExpired = () {
      _log('session expired server-side; disconnecting');
      unawaited(disconnect());
    };
    _startHeartbeat();
  }

  void _log(String message) {
    debugPrint('[ConnectionRemoteSource] $message');
  }

  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _pcConnectionController.add(connected);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_shouldBeConnected) return;

      final healthy = await checkConnection();
      _pcConnectionController.add(healthy);
    });
  }

  @override
  bool get isWebConnected => _phoneServer.isPeerConnected;

  @override
  Stream<bool> get webConnectionChanges => _phoneServer.peerConnectionChanges;

  @override
  Stream<bool> get pcConnectionChanges => _pcConnectionController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    if (_isConnecting) return;

    _isConnecting = true;
    _shouldBeConnected = true;

    _log('connect started; baseUrl=${_apiService.baseUrl}');

    try {
      final response = await _apiService.dio.post(
        '/api/phone/connect',
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final ok = response.statusCode == 200;
      _log('connect response status=${response.statusCode}');
      _updateConnectionStatus(ok);

      if (ok) {
        final created = await _sessionService.createSession();
        if (created) {
          _sessionService.startHeartbeat();
        } else {
          _log('session creation failed; status will rely on relay only');
        }
      }
    } on DioException catch (error) {
      _log('connect failed: ${error.message}');
      _updateConnectionStatus(false);
    } finally {
      _isConnecting = false;
    }
  }

  @override
  Future<void> disconnect() async {
    _shouldBeConnected = false;
    _updateConnectionStatus(false);
    _sessionService.stopHeartbeat();
    _sessionService.clearSessionId();

    if (_phoneServer.isRunning) {
      try {
        await _phoneServer.stop();
        _log('phone local HTTP server stopped on disconnect');
      } catch (e) {
        _log('error stopping phone server: $e');
      }
    }

    try {
      final response = await _apiService.dio.post(
        '/api/phone/disconnect',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      _log('disconnect response status=${response.statusCode}');
    } catch (error, stackTrace) {
      _log('disconnect request failed: $error\n$stackTrace');
    }
  }
@override
Future<bool> checkConnection() async {
  final timestamp = DateTime.now().toIso8601String();
  try {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/api/phone/status',
      options: Options(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    
    final connected =
        response.statusCode == 200 && response.data?['connected'] == true;
        
    // Log the message, timestamp, and result
    _log('[$timestamp] Connection check completed. Result: $connected, Data: ${response.data}');
    
    _updateConnectionStatus(connected);
    return connected;
  } on DioException catch (error) {
    // Log the failure message, timestamp, and error details
    _log('[$timestamp] Connection check failed. Message: ${error.message}');
    
    _updateConnectionStatus(false);
    return false;
  }
}
 @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _pcConnectionController.close();
  }
}
