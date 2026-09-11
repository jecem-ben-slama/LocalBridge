import '../../../../core/network/api_service.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/document.dart';
import '../models/document_model.dart';
import 'package:flutter/foundation.dart';
import '../../../../infrastructure/services/background_file_transfer_service.dart';

abstract interface class DocRemoteSource {
  Future<List<Document>> fetchDirectory(String? path);
  Future<File> downloadToFile(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  });
  Future<Stream<List<int>>> download(
    String path, {
    void Function(int received, int total)? onProgress,
  });
  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  });
  String getThumbnailUrl(String path);
  String getDownloadUrl(String path);
  Map<String, String> get headers;
}

class DocRemoteSourceImpl implements DocRemoteSource {
  final ApiService _apiService;
  final BackgroundFileTransferService _backgroundTransfers;

  DocRemoteSourceImpl(this._apiService, this._backgroundTransfers);

  @override
  Future<List<Document>> fetchDirectory(String? path) {
    return _fetchDirectory(path);
  }

  @override
  Future<Stream<List<int>>> download(
    String path, {
    void Function(int received, int total)? onProgress,
  }) async {
    debugPrint('[DocRemoteSource] download requested: path=$path');
    late Response<ResponseBody> response;
    try {
      response = await _apiService.dio.get<ResponseBody>(
        '/api/files/download',
        queryParameters: {'path': path},
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: onProgress,
      );
    } on DioException catch (error) {
      debugPrint(
        '[DocRemoteSource] download failed: type=${error.type}, '
        'status=${error.response?.statusCode}, '
        'message=${error.message}, data=${error.response?.data}',
      );
      rethrow;
    }
    debugPrint(
      '[DocRemoteSource] download response: status=${response.statusCode}, '
      'contentLength=${response.headers.value(Headers.contentLengthHeader)}',
    );
    return response.data!.stream;
  }

  @override
  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  }) async {
    final uri = Uri.parse(_apiService.baseUrl).replace(
      path: '/api/files/upload',
      queryParameters: {
        if (currentPath != null && currentPath.isNotEmpty) 'path': currentPath,
      },
    );
    await _backgroundTransfers.upload(
      url: uri,
      file: file,
      headers: _apiService.headers,
      fields: const {},
      onProgress: onProgress,
    );
  }

  @override
  Future<File> downloadToFile(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) {
    final uri = Uri.parse(
      _apiService.baseUrl,
    ).replace(path: '/api/files/download', queryParameters: {'path': path});
    return _backgroundTransfers.download(
      url: uri,
      fileName: fileName,
      headers: _apiService.headers,
      onProgress: onProgress ?? (_, _) {},
    );
  }

  @override
  String getThumbnailUrl(String path) =>
      _buildFileUrl('/api/files/preview', path);

  @override
  String getDownloadUrl(String path) =>
      _buildFileUrl('/api/files/download', path);

  @override
  Map<String, String> get headers => _apiService.headers;

  Future<List<Document>> _fetchDirectory(String? path) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/api/files/list',
      queryParameters: path != null && path.isNotEmpty ? {'path': path} : null,
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _buildFileUrl(String endpoint, String path) {
    final uri = Uri.parse(_apiService.baseUrl).replace(
      path: endpoint,
      queryParameters: {'path': path, ..._authQueryParameters},
    );
    return uri.toString().replaceAll('+', '%20');
  }

  Map<String, String> get _authQueryParameters {
    final token = _apiService.headers['X-Auth-Token'];
    return token == null ? const {} : {'token': token};
  }
}
