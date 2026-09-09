import '../entities/shared_file.dart';

abstract interface class SharedFilesRepository {
  Future<List<SharedFile>> listRecent();
}
