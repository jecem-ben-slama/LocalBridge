abstract interface class ConnectionRepository {
  Future<void> connectFromQr(String rawValue);

  Future<void> connectWithCode(String rawCode);
}
