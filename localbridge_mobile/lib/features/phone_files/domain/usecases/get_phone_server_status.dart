import '../repositories/phone_files_repository.dart';

class GetPhoneServerStatus {
  final PhoneFilesRepository _repository;

  GetPhoneServerStatus(this._repository);

  bool call() => _repository.isServerRunning;
}
