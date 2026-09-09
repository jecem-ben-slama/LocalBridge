import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_service.dart';

class SessionService {
  final ApiService _apiService;
  Timer? _heartbeatTimer;
  Timer? _retryTimer;
  CancelToken? _sessionCreateToken;
  bool _disposed = false;
  String? _sessionId;
  static const _heartbeatInterval = Duration(seconds: 30);

  SessionService(this._apiService);

  String? get sessionId => _sessionId;

  /// Creates or retrieves a session for the current device
  Future<bool> createSession({String? deviceName}) async {
    if (_disposed) return false;

    _sessionCreateToken?.cancel(
      'Session creation cancelled due to app shutdown.',
    );
    _sessionCreateToken = CancelToken();

    try {
      final deviceId = await _getDeviceId();
      final response = await _apiService.dio.post(
        '/api/session/create',
        data: {'deviceId': deviceId, 'deviceName': deviceName ?? 'Flutter App'},
        cancelToken: _sessionCreateToken,
      );

      if (_disposed) return false;

      if (response.statusCode == 200) {
        final sessionId = response.data['sessionId'] as String?;
        if (sessionId != null && sessionId.isNotEmpty) {
          setSessionId(sessionId);
          debugPrint('[SessionService] Session created: $sessionId');
          return true;
        }
      }
      return false;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel || _disposed) {
        debugPrint('[SessionService] Session creation cancelled');
        return false;
      }
      debugPrint('[SessionService] Failed to create session: $error');
      return false;
    } catch (error) {
      debugPrint('[SessionService] Failed to create session: $error');
      return false;
    }
  }

  /// Sets the session ID and configures API service
  void setSessionId(String sessionId) {
    _sessionId = sessionId;
    _apiService.setSessionId(sessionId);
    debugPrint('[SessionService] Session ID configured: $sessionId');
  }

  /// Clears the session ID
  void clearSessionId() {
    _sessionId = null;
    _apiService.clearSessionId();
    debugPrint('[SessionService] Session ID cleared');
  }

  /// Starts a periodic heartbeat to keep the session alive
  void startHeartbeat() {
    if (_disposed || _heartbeatTimer != null) return;
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendHeartbeat(),
    );
    debugPrint('[SessionService] Heartbeat started');
  }

  /// Stops the heartbeat timer
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _sessionCreateToken?.cancel('Session lifecycle stopped.');
    _sessionCreateToken = null;
    debugPrint('[SessionService] Heartbeat stopped');
  }

  /// Sends a heartbeat to keep session alive
  Future<bool> _sendHeartbeat() async {
    try {
      await _apiService.dio.get('/api/session/heartbeat');
      return true;
    } catch (error) {
      debugPrint('[SessionService] Heartbeat failed: $error');
      return false;
    }
  }

  /// Refreshes the session to keep it alive
  Future<bool> refreshSession() async {
    try {
      await _apiService.dio.post('/api/session/refresh');
      debugPrint('[SessionService] Session refreshed');
      return true;
    } catch (error) {
      debugPrint('[SessionService] Session refresh failed: $error');
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    stopHeartbeat();
    clearSessionId();
  }

  /// Gets a unique device identifier
  Future<String> _getDeviceId() async {
    // For now, use a simple identifier. In production, consider using
    // device_info_plus or similar to get a unique hardware ID
    return 'flutter-device-${Platform.operatingSystem}';
  }
}
