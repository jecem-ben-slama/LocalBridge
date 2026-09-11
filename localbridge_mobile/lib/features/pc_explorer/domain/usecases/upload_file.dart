import 'dart:io';
import 'package:localbridge_mobile/features/pc_explorer/domain/repositories/document_repository.dart';

class UploadFile {
  final DocumentRepository _repository;
  UploadFile(this._repository);
  
  Future<void> upload(
    String? currentPath,
    File file,
    void Function(int sent, int total) onProgress,
  ) async {
    return _repository.uploadFile(
      currentPath: currentPath,
      file: file,
      onProgress: onProgress,
    );
  }
}
