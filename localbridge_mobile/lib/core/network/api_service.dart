import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class ApiService {
  final Dio dio;
  String? _sessionId;

  ApiService({Dio? dio})
    : dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.defaultApiUrl)) {
    // Add interceptor to include session ID in all requests
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_sessionId != null && _sessionId!.isNotEmpty) {
            options.headers['X-Session-Id'] = _sessionId;
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 Unauthorized - session expired
          if (error.response?.statusCode == 401) {
            debugPrint(
              '[ApiService] Session expired or invalid - received 401 Unauthorized',
            );
            clearSessionId();
          }
          return handler.next(error);
        },
      ),
    );
  }

  String? get sessionId => _sessionId;

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
    debugPrint('[ApiService] Session ID set: $sessionId');
  }

  void clearSessionId() {
    _sessionId = null;
    debugPrint('[ApiService] Session ID cleared');
  }

  String get baseUrl => dio.options.baseUrl;

  String? get authToken => dio.options.headers['X-Auth-Token']?.toString();

  void configure({required String host, String? token}) {
    final normalizedHost = _normalizeHost(host);
    debugPrint(
      '[ApiService] configuring baseUrl=$normalizedHost, tokenPresent=${token != null}',
    );
    dio.options.baseUrl = normalizedHost;
    if (token != null) {
      dio.options.headers['X-LocalBridge-Token'] = token;
      dio.options.headers['X-Auth-Token'] = token;
    } else {
      dio.options.headers.remove('X-LocalBridge-Token');
      dio.options.headers.remove('X-Auth-Token');
    }
  }

  Map<String, String> get headers {
    return dio.options.headers.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static String _normalizeHost(String host) {
    final normalized = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;
    return normalized;
  }
}
