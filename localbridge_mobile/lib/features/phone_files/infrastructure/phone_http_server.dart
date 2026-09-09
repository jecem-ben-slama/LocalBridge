import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/services/phone_server.dart';

class _ResponseStreamException implements Exception {
  final Object cause;

  const _ResponseStreamException(this.cause);
}

class PhoneHttpServer implements PhoneServer {
  static const _idleTimeout = Duration(seconds: 60);
  static const _idleCheckInterval = Duration(seconds: 10);
  static const _peerTimeout = Duration(seconds: 30);

  HttpServer? _server;
  Directory? _rootDirectory;
  String? _authToken;
  String? _advertisedAddress;
  Timer? _idleTimer;
  DateTime? _lastHeartbeat;
  int _activeRequests = 0;
  bool _stopping = false;
  bool _peerConnected = false;
  final _peerConnectionController = StreamController<bool>.broadcast();

  @override
  bool get isRunning => _server != null && !_stopping;

  @override
  bool get isPeerConnected => isRunning && _peerConnected;

  @override
  Stream<bool> get peerConnectionChanges => _peerConnectionController.stream;

  @override
  Future<PhoneServerInfo> start({
    required Directory rootDirectory,
    required String authToken,
  }) async {
    if (isRunning) return _serverInfo();

    _rootDirectory = rootDirectory;
    await Directory(
      '${rootDirectory.path}${Platform.pathSeparator}LocalBridge',
    ).create(recursive: true);
    _authToken = authToken;
    _lastHeartbeat = DateTime.now();
    _setPeerConnected(false);
    _stopping = false;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    try {
      _advertisedAddress = await _resolveAdvertisedAddress();
    } catch (_) {
      await server.close(force: true);
      rethrow;
    }
    _server = server;
    server.listen(_handleRequest, onError: _handleServerError);
    _idleTimer = Timer.periodic(_idleCheckInterval, (_) => _stopWhenIdle());
    _log('started on ${server.address.address}:${server.port}');
    return _serverInfo();
  }

  @override
  Future<void> stop() async {
    final server = _server;
    if (server == null) return;

    _stopping = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    _server = null;
    _rootDirectory = null;
    _authToken = null;
    _advertisedAddress = null;
    _lastHeartbeat = null;
    _setPeerConnected(false);
    await server.close(force: true);
    _log('stopped');
  }

  PhoneServerInfo _serverInfo() {
    final server = _server;
    if (server == null) {
      throw StateError('Phone server is not running');
    }
    return PhoneServerInfo(
      baseUrl: 'http://${_advertisedAddress ?? _localAddress()}:${server.port}',
      port: server.port,
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _activeRequests++;
    try {
      _setCorsHeaders(request.response);
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      if (!_isAuthorized(request)) {
        await _sendJson(request.response, HttpStatus.unauthorized, {
          'success': false,
          'message': 'Unauthorized',
        });
        return;
      }

      if (request.uri.path == '/health') {
        _lastHeartbeat = DateTime.now();
        _setPeerConnected(true);
        await _sendJson(request.response, HttpStatus.ok, {'ok': true});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/upload') {
        await _uploadFile(request);
        return;
      }
      if (request.method != 'GET') {
        await _sendJson(request.response, HttpStatus.methodNotAllowed, {
          'success': false,
          'message': 'Method not allowed',
        });
        return;
      }

      switch (request.uri.path) {
        case '/browse':
          await _browse(request);
        case '/download':
        case '/preview':
          await _streamFile(request);
        default:
          await _sendJson(request.response, HttpStatus.notFound, {
            'success': false,
            'message': 'Not found',
          });
      }
    } catch (error, stackTrace) {
      _log('request failed: $error\n$stackTrace');
      if (error is! _ResponseStreamException) {
        try {
          await _sendJson(request.response, HttpStatus.badRequest, {
            'success': false,
            'message': _userFacingMessage(error),
          });
        } catch (_) {
          // The client may have disconnected before the error response.
        }
      }
    } finally {
      _activeRequests--;
      if (_activeRequests < 0) {
        _activeRequests = 0;
      }
    }
  }

  String _userFacingMessage(Object error) {
    final message = error.toString();
    if (message.contains('does not exist')) {
      return 'The requested file or folder was not found.';
    }
    if (message.contains('Access denied')) {
      return 'That location is not available.';
    }
    if (message.contains('Missing file name') ||
        message.contains('Invalid file name')) {
      return 'The uploaded file name is not valid.';
    }
    if (message.contains('Destination directory')) {
      return 'The selected folder is not available.';
    }
    return 'The phone could not complete that request.';
  }

  Future<void> _browse(HttpRequest request) async {
    final directory = Directory(
      await _safePath(request.uri.queryParameters['path'] ?? ''),
    );
    if (!await directory.exists()) {
      throw StateError('Directory does not exist');
    }

    final files = <Map<String, Object>>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (_isHiddenOrFilesEntry(name)) continue;
      final type = await entity.stat();
      files.add({
        'name': name,
        'path': _relativePath(entity.path),
        'isDirectory': type.type == FileSystemEntityType.directory,
      });
    }
    files.sort((left, right) {
      final directoryOrder =
          (right['isDirectory'] as bool ? 1 : 0) -
          (left['isDirectory'] as bool ? 1 : 0);
      if (directoryOrder != 0) return directoryOrder;
      return (left['name'] as String).toLowerCase().compareTo(
        (right['name'] as String).toLowerCase(),
      );
    });
    await _sendJson(request.response, HttpStatus.ok, {
      'success': true,
      'data': files,
    });
  }

  Future<void> _streamFile(HttpRequest request) async {
    final file = File(
      await _safePath(request.uri.queryParameters['path'] ?? ''),
    );
    if (!await file.exists()) throw StateError('File does not exist');
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw StateError('Path is not a file');
    }

    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.parse(_contentType(file.path));
    response.contentLength = stat.size;
    if (request.uri.path == '/download') {
      final name = file.path.split(Platform.pathSeparator).last;
      response.headers.set(
        'content-disposition',
        'attachment; filename="${_headerSafe(name)}"',
      );
    }
    try {
      await response.addStream(file.openRead());
      await response.close();
    } catch (error) {
      throw _ResponseStreamException(error);
    }
  }

  Future<void> _uploadFile(HttpRequest request) async {
    final rawName =
        request.headers.value('X-File-Name') ??
        request.uri.queryParameters['name'];
    if (rawName == null || rawName.trim().isEmpty) {
      throw StateError('Missing file name');
    }
    final fileName = Uri.decodeComponent(
      rawName,
    ).split('/').last.split('\\').last;
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      throw StateError('Invalid file name');
    }
    if (_isHiddenOrFilesEntry(fileName)) {
      throw StateError('Hidden files are not allowed');
    }
    final requestedPath = request.uri.queryParameters['path'];
    final destinationDirectory = Directory(
      await _safePath(
        requestedPath == null || requestedPath.isEmpty
            ? 'LocalBridge'
            : requestedPath,
      ),
    );
    if (!await destinationDirectory.exists()) {
      throw StateError('Destination directory does not exist');
    }
    final destinationStat = await destinationDirectory.stat();
    if (destinationStat.type != FileSystemEntityType.directory) {
      throw StateError('Upload destination is not a directory');
    }
    final destination = File(
      '${destinationDirectory.path}${Platform.pathSeparator}$fileName',
    );
    final temporary = File(
      '${destination.path}.part-${DateTime.now().microsecondsSinceEpoch}',
    );
    final sink = temporary.openWrite();
    try {
      await request.forEach(sink.add);
      await sink.flush();
      await sink.close();
      await temporary.rename(destination.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    } finally {
      await sink.close();
    }
    await _sendJson(request.response, HttpStatus.ok, {
      'success': true,
      'name': fileName,
    });
  }

  bool _isAuthorized(HttpRequest request) {
    final expected = _authToken;
    if (expected == null || expected.isEmpty) return false;

    final localBridgeToken = request.headers.value('X-LocalBridge-Token');
    final authToken = request.headers.value('X-Auth-Token');
    final authorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );
    final bearerToken =
        authorization != null && authorization.startsWith('Bearer ')
        ? authorization.substring('Bearer '.length)
        : null;
    final queryToken =
        request.uri.queryParameters['token'] ??
        request.uri.queryParameters['pairing_token'];

    final credentials = <String, String>{};
    if (localBridgeToken != null) {
      credentials['localbridge'] = localBridgeToken;
    }
    if (authToken != null) {
      credentials['auth'] = authToken;
    }
    if (bearerToken != null) {
      credentials['bearer'] = bearerToken;
    }
    if (queryToken != null) {
      credentials['query'] = queryToken;
    }
    final matchingSource = credentials.entries
        .where((entry) => entry.value.trim() == expected.trim())
        .map((entry) => entry.key)
        .firstOrNull;
    final authorized = matchingSource != null;
    if (!authorized) {
      _log(
        'unauthorized ${request.method} ${request.uri.path}; '
        'credentialPresent=${credentials.isNotEmpty}, '
        'credentialSources=${credentials.keys.join(',')}',
      );
    } else if (credentials.length > 1) {
      _log(
        'authorized ${request.method} ${request.uri.path}; '
        'matchingSource=$matchingSource, receivedSources=${credentials.keys.join(',')}',
      );
    }
    return authorized;
  }

  Future<String> _safePath(String requestedPath) async {
    final root = _rootDirectory;
    if (root == null) throw StateError('Phone server is not ready');
    final normalized = requestedPath
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/sdcard(?=/|$)'), '')
        .replaceFirst(RegExp(r'^/storage/emulated/0(?=/|$)'), '');
    if (normalized.split('/').any((segment) => segment == '..')) {
      throw StateError('Access denied');
    }
    final target = File(
      '${root.path}${Platform.pathSeparator}$normalized',
    ).absolute;
    final rootPath = root.absolute.path.endsWith(Platform.pathSeparator)
        ? root.absolute.path
        : '${root.absolute.path}${Platform.pathSeparator}';
    if (target.path != root.absolute.path &&
        !target.path.startsWith(rootPath)) {
      throw StateError('Access denied');
    }
    final realRoot = await root.resolveSymbolicLinks();
    final realTarget = await target.resolveSymbolicLinks();
    if (realTarget != realRoot &&
        !realTarget.startsWith('$realRoot${Platform.pathSeparator}')) {
      throw StateError('Access denied');
    }
    return realTarget;
  }

  bool _isHiddenOrFilesEntry(String name) =>
      name.startsWith('.') || name.toLowerCase() == '.files';

  String _relativePath(String path) => path
      .substring(_rootDirectory!.absolute.path.length)
      .replaceAll(Platform.pathSeparator, '/')
      .replaceFirst(RegExp(r'^/'), '');

  Future<void> _sendJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object> body,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set(
        'Access-Control-Allow-Headers',
        'X-Session-Id, X-LocalBridge-Token, X-Auth-Token, X-File-Name, Content-Type, Authorization',
      )
      ..set('Access-Control-Max-Age', '600');
  }

  void _stopWhenIdle() {
    final lastHeartbeat = _lastHeartbeat;
    if (lastHeartbeat == null) return;
    if (DateTime.now().difference(lastHeartbeat) >= _peerTimeout) {
      _setPeerConnected(false);
    }
    if (_activeRequests > 0) return;
    if (DateTime.now().difference(lastHeartbeat) >= _idleTimeout) {
      unawaited(stop());
    }
  }

  void _setPeerConnected(bool connected) {
    if (_peerConnected == connected) return;
    _peerConnected = connected;
    _peerConnectionController.add(connected);
  }

  String _localAddress() => _server?.address.address ?? '0.0.0.0';

  Future<String> _resolveAdvertisedAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback && address.address != '0.0.0.0') {
          return address.address;
        }
      }
    }
    throw StateError(
      'No local network address is available for the phone server.',
    );
  }

  String _headerSafe(String value) => value.replaceAll(RegExp(r'[\r\n"]'), '_');

  String _contentType(String path) {
    const types = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.mp4': 'video/mp4',
      '.pdf': 'application/pdf',
      '.txt': 'text/plain',
    };
    final lower = path.toLowerCase();
    return types.entries
        .firstWhere(
          (entry) => lower.endsWith(entry.key),
          orElse: () => const MapEntry('', 'application/octet-stream'),
        )
        .value;
  }

  void _handleServerError(Object error, StackTrace stackTrace) {
    _log('server error: $error\n$stackTrace');
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[PhoneHttpServer] $message');
  }
}
