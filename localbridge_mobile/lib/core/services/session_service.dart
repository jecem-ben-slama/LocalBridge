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
  DateTime? _lastActivity;
  int _consecutiveFailures = 0;

  static const _heartbeatInterval = Duration(seconds: 30);
  // How long a single heartbeat failure is tolerated before retrying sooner
  // than the next periodic tick. Keeps a transient blip from silently
  // eating up to 30s of the idle budget.
  static const _retryBackoff = Duration(seconds: 5);
  static const _maxRetryBackoff = Duration(seconds: 20);

  // If any request (heartbeat OR real API traffic) succeeded within this
  // window, we consider the session locally "known alive" without needing
  // a fresh network round trip. Kept slightly above the heartbeat interval
  // so normal periodic beats always fall inside it.
  static const activityGraceWindow = Duration(seconds: 45);

  /// Called when the server tells us, via a heartbeat response, that our
  /// session has expired or no longer exists (e.g. the backend idle-
  /// disconnected it). This is distinct from a network/heartbeat *failure*
  /// - it's an explicit "you are no longer connected" from the backend.
  /// The owner (ConnectionRemoteSourceImpl) is expected to react by tearing
  /// down the local phone server and connection state.
  void Function()? onSessionExpired;

  SessionService(this._apiService) {
    // Any successful request (browsing, download, upload, heartbeat...)
    // counts as activity. This is what actually implements "stay alive
    // while using it" instead of relying solely on the heartbeat timer.
    _apiService.onActivity = _recordActivity;
  }

  String? get sessionId => _sessionId;

  /// True if we've seen successful traffic recently enough that we can
  /// trust the session is alive without making a new network call.
  bool get isRecentlyActive =>
      _lastActivity != null &&
      DateTime.now().difference(_lastActivity!) < activityGraceWindow;

  void _recordActivity() {
    _lastActivity = DateTime.now();
    _consecutiveFailures = 0;
  }

  /// Call this when the app resumes from background (e.g. from a
  /// WidgetsBindingObserver.didChangeAppLifecycleState) to immediately
  /// re-validate instead of waiting for the next periodic heartbeat.
  void onAppResumed() {
    if (_disposed || _heartbeatTimer == null) return;
    unawaited(_sendHeartbeat());
  }

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
          _recordActivity();
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
    _lastActivity = null;
    _apiService.clearSessionId();
    debugPrint('[SessionService] Session ID cleared');
  }

  /// Starts a periodic heartbeat to keep the session alive.
  /// Fires immediately, then every [_heartbeatInterval].
  void startHeartbeat() {
    if (_disposed || _heartbeatTimer != null) return;
    unawaited(_sendHeartbeat());
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
    _consecutiveFailures = 0;
    _sessionCreateToken?.cancel('Session lifecycle stopped.');
    _sessionCreateToken = null;
    debugPrint('[SessionService] Heartbeat stopped');
  }

  /// Sends a heartbeat to keep session alive. On failure, schedules a
  /// short-backoff retry instead of waiting for the next periodic tick,
  /// so one dropped beat can't silently burn through the idle timeout.
  ///
  /// A successful response with active: false means the backend has
  /// explicitly expired/closed this session (e.g. idle timeout) - that's
  /// not a network failure, so it's handled separately via
  /// onSessionExpired rather than the retry/backoff path.
  Future<bool> _sendHeartbeat() async {
    _retryTimer?.cancel();
    _retryTimer = null;

    try {
      final response = await _apiService.dio.get('/api/session/heartbeat');
      final data = response.data;
      final active = data is Map ? data['active'] != false : true;

      if (!active) {
        debugPrint('[SessionService] Session expired server-side');
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        onSessionExpired?.call();
        return false;
      }

      _recordActivity();
      return true;
    } catch (error) {
      _consecutiveFailures++;
      debugPrint(
        '[SessionService] Heartbeat failed (attempt $_consecutiveFailures): $error',
      );

      if (_disposed || _heartbeatTimer == null) return false;

      final backoff = _retryBackoff * _consecutiveFailures;
      final delay = backoff > _maxRetryBackoff ? _maxRetryBackoff : backoff;
      _retryTimer = Timer(delay, () {
        if (!_disposed && _heartbeatTimer != null) {
          _sendHeartbeat();
        }
      });
      return false;
    }
  }

  /// Refreshes the session to keep it alive
  Future<bool> refreshSession() async {
    try {
      await _apiService.dio.post('/api/session/refresh');
      _recordActivity();
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
    return 'flutter-device-${Platform.operatingSystem}';
  }
}