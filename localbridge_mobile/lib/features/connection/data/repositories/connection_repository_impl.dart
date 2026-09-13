import 'package:localbridge_mobile/core/constants/app_constants.dart';
import 'package:localbridge_mobile/core/network/api_service.dart';
import 'package:localbridge_mobile/features/connection/data/datasource/connection_remote_source.dart';
import 'package:localbridge_mobile/features/connection/domain/repositories/connection_repository.dart';
import 'package:localbridge_mobile/injection_container.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionRemoteSource _remoteSource;

  ConnectionRepositoryImpl(this._remoteSource);

  @override
  Future<void> connectFromQr(String rawValue) async {
    final uri = Uri.tryParse(rawValue);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw Exception('This QR code is not a valid LocalBridge pairing code.');
    }

    final token = _extractToken(uri);
    if (token == null || token.isEmpty) {
      throw Exception('This QR code is missing a pairing token.');
    }

    final host =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    locator<ApiService>().configure(host: host, token: token);

    await _remoteSource.connect();
  }

  @override
  Future<void> connectWithCode(String rawCode) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      throw Exception('Enter the pairing code shown on the web app.');
    }

    String host = AppConstants.defaultApiUrl;
    String token = trimmed;

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && parsed.hasAuthority) {
      host =
          '${parsed.scheme}://${parsed.host}${parsed.hasPort ? ':${parsed.port}' : ''}';
      final parsedToken = _extractToken(parsed);
      if (parsedToken != null && parsedToken.isNotEmpty) {
        token = parsedToken;
      }
    }

    locator<ApiService>().configure(host: host, token: token);
    await _remoteSource.connect();
  }

  @override
  Future<void> disconnect() => _remoteSource.disconnect();

  @override
  bool get isConnected => _remoteSource.isConnected;

  @override
  Future<bool> checkConnection() => _remoteSource.checkConnection();

  @override
  bool get isWebConnected => _remoteSource.isWebConnected;

  @override
  Stream<bool> get webConnectionChanges => _remoteSource.webConnectionChanges;

  @override
  Stream<bool> get pcConnectionChanges => _remoteSource.pcConnectionChanges;

  String? _extractToken(Uri uri) =>
      uri.queryParameters['pairing_token'] ??
      uri.queryParameters['pairing_code'] ??
      uri.queryParameters['token'];
}
