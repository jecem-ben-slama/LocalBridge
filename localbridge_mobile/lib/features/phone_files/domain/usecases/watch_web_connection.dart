import '../repositories/phone_files_repository.dart';

class WatchWebConnection {
  final PhoneFilesRepository _repository;

  WatchWebConnection(this._repository);

  Stream<bool> call() => _repository.webConnectionChanges;
}
