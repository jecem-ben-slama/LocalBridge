import 'package:dio/dio.dart';

String userMessage(Object error, {String fallback = 'Something went wrong.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The connection took too long. Check that the PC is available.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Could not reach the PC. Check the network connection.';
    }
    if (error.response?.statusCode == 413) {
      return 'This file is larger than the allowed upload size.';
    }
  }
  final message = error.toString();
  if (message.startsWith('Exception: ')) return message.substring(11);
  if (message.startsWith('Bad state: ')) return message.substring(11);
  if (message.contains('SocketException') ||
      message.contains('Failed host lookup')) {
    return 'Could not reach the PC. Check the network connection.';
  }
  return message.isEmpty ? fallback : message;
}
