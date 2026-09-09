import '../repositories/phone_files_repository.dart';

class DisconnectPhoneSession {
  final PhoneFilesRepository _repository;

  DisconnectPhoneSession(this._repository);

  Future<void> call() => _repository.disconnect();
}
