import '../repositories/phone_files_repository.dart';

class GetPhoneServerStatusStream {
  final PhoneFilesRepository _repository;

  GetPhoneServerStatusStream(this._repository);

  Stream<bool> call() => _repository.serverStatusStream;
}