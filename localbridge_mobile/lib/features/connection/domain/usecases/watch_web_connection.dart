import '../repositories/connection_repository.dart';

class WatchWebConnection {
  final ConnectionRepository _repository;

  WatchWebConnection(this._repository);


  Stream<bool> call() => _repository.pcConnectionChanges;
}
