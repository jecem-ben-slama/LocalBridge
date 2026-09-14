import '../repositories/connection_repository.dart';
import '../../../../core/services/session_service.dart';

class CheckPcConnectivity {
  final ConnectionRepository _repository;
  final SessionService _sessionService;

  CheckPcConnectivity(this._repository, this._sessionService);

  Future<bool> call() async {
    // If we've had successful traffic very recently, trust that instead of
    // firing another network round trip — avoids UI flicker to
    // "disconnected" on a single transient blip while the session is
    // actually fine.
    if (_sessionService.isRecentlyActive) return true;

    try {
      return await _repository.checkConnection();
    } catch (_) {
      return false;
    }
  }
}