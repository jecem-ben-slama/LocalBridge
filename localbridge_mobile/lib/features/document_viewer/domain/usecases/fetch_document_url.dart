import '../repositories/document_repository.dart';

class FetchDocumentUrl {
  final DocumentRepository _repository;

  FetchDocumentUrl(this._repository);

  String call(String path) => _repository.getDownloadUrl(path);
}
