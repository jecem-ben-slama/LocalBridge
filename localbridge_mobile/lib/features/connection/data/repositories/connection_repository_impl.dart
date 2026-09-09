import 'package:localbridge_mobile/core/constants/app_constants.dart';
import 'package:localbridge_mobile/core/network/api_service.dart';
import 'package:localbridge_mobile/features/connection/domain/repositories/connection_repository.dart';
import 'package:localbridge_mobile/features/phone_files/domain/repositories/phone_files_repository.dart';
import 'package:localbridge_mobile/injection_container.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final PhoneFilesRepository _phoneFilesRepository;

  ConnectionRepositoryImpl(this._phoneFilesRepository);

  @override
  Future<void> connectFromQr(String rawValue) async {
    final uri = Uri.tryParse(rawValue);

    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final token =
          uri.queryParameters['pairing_token'] ??
          uri.queryParameters['pairing_code'] ??
          uri.queryParameters['token'];
      final host =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      locator<ApiService>().configure(host: host, token: token ?? '');
    } else {
      locator<ApiService>().configure(host: rawValue, token: '');
    }

    await _phoneFilesRepository.connect();
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
      final parsedToken =
          parsed.queryParameters['pairing_token'] ??
          parsed.queryParameters['pairing_code'] ??
          parsed.queryParameters['token'];
      if (parsedToken != null && parsedToken.isNotEmpty) {
        token = parsedToken;
      }
    }

    locator<ApiService>().configure(host: host, token: token);
    await _phoneFilesRepository.connect();
  }
}
