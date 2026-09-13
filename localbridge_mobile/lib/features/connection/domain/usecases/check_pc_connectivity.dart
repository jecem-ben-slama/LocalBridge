import '../repositories/connection_repository.dart';

class CheckPcConnectivity {
  final ConnectionRepository _repository;

  CheckPcConnectivity(this._repository);

  Future<bool> call() async {
    try {
      return await _repository.checkConnection();
    } catch (_) {
      return false;
    }
  }
}
