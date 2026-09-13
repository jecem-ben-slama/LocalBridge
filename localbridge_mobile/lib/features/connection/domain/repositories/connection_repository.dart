abstract interface class ConnectionRepository {
  Future<void> connectFromQr(String rawValue);

  Future<void> connectWithCode(String rawCode);

  Future<void> disconnect();

  bool get isConnected;

  Future<bool> checkConnection();

  bool get isWebConnected;

  Stream<bool> get webConnectionChanges;

  Stream<bool> get pcConnectionChanges;
}
