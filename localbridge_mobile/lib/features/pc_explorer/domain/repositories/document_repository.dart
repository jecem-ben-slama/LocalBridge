import '../entities/document.dart';
import 'dart:io';

abstract interface class DocumentRepository {
  
  Future<List<Document>> fetchDirectory(String? path);
  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  });
  String getThumbnailUrl(String path);
  String getDownloadUrl(String path);
  Map<String, String> get headers;
  Future<String> download(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  });

  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  });
}
