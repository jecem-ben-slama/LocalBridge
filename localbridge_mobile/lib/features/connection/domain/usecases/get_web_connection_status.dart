import '../../../phone_files/domain/repositories/phone_files_repository.dart';

class GetWebConnectionStatus {
  final PhoneFilesRepository _repository;

  GetWebConnectionStatus(this._repository);

  bool call() => _repository.isWebConnected;
}
