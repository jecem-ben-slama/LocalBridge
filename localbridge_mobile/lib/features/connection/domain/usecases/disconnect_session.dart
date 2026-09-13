import '../../../phone_files/domain/repositories/phone_files_repository.dart';
import '../repositories/connection_repository.dart';

/// Ends the pairing session and makes sure the phone stops serving files
/// once there's no active session for them to be served under.
///
/// This orchestration belongs in a use case, not in either repository:
/// repositories stay single-purpose, use cases are where cross-feature
/// business rules like "disconnecting also stops the server" live.
class DisconnectSession {
  final ConnectionRepository _connectionRepository;
  final PhoneFilesRepository _phoneFilesRepository;

  DisconnectSession(this._connectionRepository, this._phoneFilesRepository);

  Future<void> call() async {
    await _phoneFilesRepository.stopServer();
    await _connectionRepository.disconnect();
  }
}
