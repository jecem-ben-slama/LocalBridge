import 'package:localbridge_mobile/features/pc_explorer/domain/repositories/document_repository.dart';

class DownloadFile {
  final DocumentRepository _repository;
  DownloadFile(this._repository);

  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }
   ){
    return  _repository.downloadToLocation(path, fileName, onProgress: onProgress);
  }
}
