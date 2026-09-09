import '../entities/shared_file.dart';
import '../repositories/shared_files_repository.dart';

class LoadRecentSharedFiles {
  final SharedFilesRepository _repository;

  LoadRecentSharedFiles(this._repository);

  Future<List<SharedFile>> call() => _repository.listRecent();
}
