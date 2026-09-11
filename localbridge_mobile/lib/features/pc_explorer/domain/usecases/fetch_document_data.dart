import '../repositories/document_repository.dart';

class FetchDocumentData {
  final DocumentRepository _repository;

  FetchDocumentData(this._repository);

  String call(String path) => _repository.getDownloadUrl(path);
  
  Map<String, String> get headers => _repository.headers;

  String getThumbnailUrl(String path) => _repository.getThumbnailUrl(path);

  String getDownloadUrl(String path) => _repository.getDownloadUrl(path);

}
