import 'dart:io';
import 'package:dio/dio.dart';

String userMessage(Object error, {String fallback = 'Something went wrong.'}) {
  if (error is DioException) {
    // 1. Try extracting server-provided message
    final serverMessage = _extractServerMessage(error.response?.data);
    if (serverMessage != null) return serverMessage;

    // 2. Handle specific network/timeout issues
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The connection took too long. Check that the server is available.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your network connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Security certificate validation failed.';
      case DioExceptionType.badResponse:
        return _messageForStatusCode(error.response?.statusCode) ?? fallback;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'Could not reach the server. Check your network connection.';
        }
        break;
      case DioExceptionType.transformTimeout:
        throw UnimplementedError();
    }
  }

  // 3. Handle raw SocketException or Host Lookup failures outside Dio
  if (error is SocketException) {
    return 'Could not reach the server. Check your network connection.';
  }

  // 4. Format generic exceptions cleanly
  final rawMessage = error.toString().trim();

  if (rawMessage.startsWith('Exception: ')) {
    return rawMessage.substring(11).trim();
  }
  if (rawMessage.startsWith('Bad state: ')) {
    return rawMessage.substring(11).trim();
  }
  if (rawMessage.contains('SocketException') ||
      rawMessage.contains('Failed host lookup')) {
    return 'Could not reach the server. Check your network connection.';
  }

  return rawMessage.isEmpty ? fallback : rawMessage;
}

/// Safely extracts custom backend error messages across common API JSON structures.
String? _extractServerMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final candidate = data['message'] ?? data['error'] ?? data['detail'];

    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }

    // Handle list of validation errors: e.g., { "errors": ["Invalid email"] }
    if (candidate is List && candidate.isNotEmpty) {
      return candidate.first.toString().trim();
    }
  }
  return null;
}

/// Maps HTTP status codes to user-friendly messages when backend doesn't provide one.
String? _messageForStatusCode(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'Invalid request format.';
    case 401:
      return 'Unauthorized. Please sign in again.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'The requested resource was not found.';
    case 413:
      return 'This file is larger than the allowed upload size.';
    case 429:
      return 'Too many requests. Please try again in a moment.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'Server error. Please try again later.';
    default:
      return null;
  }
}
