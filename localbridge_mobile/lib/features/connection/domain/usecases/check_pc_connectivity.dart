import '../../../phone_files/domain/repositories/phone_files_repository.dart';

class CheckPcConnectivity {
  final PhoneFilesRepository _phoneFilesRepository;

  CheckPcConnectivity(this._phoneFilesRepository);

  Future<bool> call() async {
    try {
      return await _phoneFilesRepository.checkConnection();
    } catch (_) {
      return false;
    }
  }
}
