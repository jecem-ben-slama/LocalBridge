import '../repositories/connection_repository.dart';

class WatchWebConnection {
  final ConnectionRepository _repository;

  WatchWebConnection(this._repository);

  Stream<bool> call() async* {
    // 1. Actively verify connection once on startup so it doesn't default to red/false
    try {
      final initialStatus = await _repository.checkConnection();
      yield initialStatus;
    } catch (_) {
      yield false;
    }

    // 2. Yield subsequent real-time changes from the stream
    yield* _repository.webConnectionChanges;
  }
}
