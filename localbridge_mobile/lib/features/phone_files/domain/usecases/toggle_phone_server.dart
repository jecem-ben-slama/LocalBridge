import '../repositories/phone_files_repository.dart';

class TogglePhoneServer {
  final PhoneFilesRepository _repository;

  TogglePhoneServer(this._repository);

  Future<void> call({required bool isRunning}) async {
    if (isRunning) {
      await _repository.stopServer();
      return;
    }

    await _repository.startServer();
  }
}
