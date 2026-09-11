import '../../domain/entities/document.dart';
import 'dart:io';
import '../../../../core/services/file_storage_service.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/doc_remote_source.dart';
class DocumentRepositoryImpl implements DocumentRepository {
  final DocRemoteSource _remoteSource;
  final FileStorageService _fileStorage;

  DocumentRepositoryImpl(this._remoteSource, this._fileStorage);

  @override
  Future<List<Document>> fetchDirectory(String? path) {
    return _remoteSource.fetchDirectory(path);
  }

  @override
  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _remoteSource.uploadFile(
      currentPath: currentPath,
      file: file,
      onProgress: onProgress,
    );
  }

  @override
  String getThumbnailUrl(String path) => _remoteSource.getThumbnailUrl(path);

  @override
  String getDownloadUrl(String path) => _remoteSource.getDownloadUrl(path);

  @override
  Map<String, String> get headers => _remoteSource.headers;

  @override
  Future<String> download(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) {
    return _remoteSource
        .downloadToFile(path, fileName, onProgress: onProgress)
        .then((file) => file.path);
  }

  @override
  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    final stream = await _remoteSource.download(path, onProgress: onProgress);
    return _fileStorage.saveStreamWithPicker(fileName, stream);
  }
}
