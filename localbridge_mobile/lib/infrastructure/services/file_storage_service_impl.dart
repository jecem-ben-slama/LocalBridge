import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/file_storage_service.dart';

class FileStorageServiceImpl implements FileStorageService {
  @override
  Future<String> saveStreamWithPicker(
    String fileName,
    Stream<List<int>> bytes,
  ) async {
    final safeName = _safeFileName(fileName);
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose download folder',
    );
    debugPrint(
      '[FileStorageService] selected download directory=$selectedDirectory',
    );
    if (selectedDirectory == null || selectedDirectory.isEmpty) {
      throw StateError('Save cancelled');
    }
    final selectedPath = '$selectedDirectory${Platform.pathSeparator}$safeName';
    await Directory(selectedDirectory).create(recursive: true);
    final sink = File(selectedPath).openWrite();
    try {
      await for (final chunk in bytes) {
        sink.add(chunk);
      }
      await sink.flush();
      return selectedPath;
    } catch (_) {
      rethrow;
    } finally {
      await sink.close();
    }
  }

  @override
  Future<String> saveStream(String fileName, Stream<List<int>> bytes) async {
    final safeName = _safeFileName(fileName);
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getDownloadsDirectory();
    if (directory == null) {
      throw StateError('No writable download directory is available.');
    }
    final filePath = '${directory.path}${Platform.pathSeparator}$safeName';
    final sink = File(filePath).openWrite();
    try {
      await for (final chunk in bytes) {
        sink.add(chunk);
      }
      await sink.flush();
      return filePath;
    } finally {
      await sink.close();
    }
  }

  String _safeFileName(String fileName) {
    final normalized = fileName.replaceAll('\\', '/').split('/').last.trim();
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('.') ||
        normalized.toLowerCase() == '.files') {
      throw StateError('Invalid or hidden file name.');
    }
    return normalized;
  }
}
