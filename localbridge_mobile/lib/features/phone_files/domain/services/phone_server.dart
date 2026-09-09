import 'dart:io';

class PhoneServerInfo {
  final String baseUrl;
  final int port;

  const PhoneServerInfo({required this.baseUrl, required this.port});
}

abstract interface class PhoneServer {
  bool get isRunning;

  bool get isPeerConnected;

  Stream<bool> get peerConnectionChanges;

  Future<PhoneServerInfo> start({
    required Directory rootDirectory,
    required String authToken,
  });

  Future<void> stop();
}
