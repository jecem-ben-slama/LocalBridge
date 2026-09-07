import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/file_node.dart';

class ApiService {
  // Dynamically populated via QR Code scan (e.g., http://192.168.1.50:8080)
  static String baseUrl = 'http://10.0.2.2:8080';

  Future<List<FileNode>> fetchPcDirectory(String? path) async {
    final uri = Uri.parse('$baseUrl/api/files/list').replace(
      queryParameters: path != null && path.isNotEmpty ? {'path': path} : null,
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'];
      return data.map((item) => FileNode.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load PC directory contents');
    }
  }

  String getThumbnailUrl(String path) {
    return '$baseUrl/api/files/preview?path=${Uri.encodeComponent(path)}';
  }

  String getDownloadUrl(String path) {
    return '$baseUrl/api/files/download?path=${Uri.encodeComponent(path)}';
  }

  Future<void> uploadFileToPc({
    required String? currentPath,
    required File file,
    required Function(int sent, int total) onProgress,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/files/upload'),
    );

    if (currentPath != null && currentPath.isNotEmpty) {
      request.fields['path'] = currentPath;
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var totalBytes = streamedResponse.contentLength ?? file.lengthSync();
    var transferredBytes = 0;

    streamedResponse.stream.listen((value) {
      transferredBytes += value.length;
      onProgress(transferredBytes, totalBytes);
    }, cancelOnError: true);

    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Server rejected upload: ${response.body}');
    }
  }

  Future<String> downloadFileFromPc(String path, String fileName) async {
    final response = await http.get(Uri.parse(getDownloadUrl(path)));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$fileName');
      await localFile.writeAsBytes(response.bodyBytes);
      return localFile.path;
    } else {
      throw Exception('Failed to download file from PC');
    }
  }
}
