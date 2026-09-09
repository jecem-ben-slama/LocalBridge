import '../../domain/entities/shared_file.dart';
import '../../domain/repositories/shared_files_repository.dart';
import '../datasources/shared_files_local_source.dart';

class SharedFilesRepositoryImpl implements SharedFilesRepository {
  final SharedFilesLocalSource _source;

  SharedFilesRepositoryImpl(this._source);

  @override
  Future<List<SharedFile>> listRecent() => _source.listRecent();
}
