import '../repositories/document_repository.dart';
import '../entities/document.dart';

class LoadDirectory {
  final DocumentRepository _repository;

  LoadDirectory(this._repository);

  Future<List<Document>> call([String? path]) async {
    return _repository.fetchDirectory(path);
  }
}
