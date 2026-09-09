import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundFileTransferService {
  static const int _maxAttempts = 2;
  Task? _activeTask;

  Future<void> upload({
    required Uri url,
    required File file,
    required Map<String, String> headers,
    required Map<String, String> fields,
    required void Function(int sent, int total) onProgress,
  }) async {
    final sourcePath = file.absolute.path;
    final stagedFile = await _stageUploadFile(file);
    final metadata = _metadata({
      'sourcePath': sourcePath,
      'endpoint': url.path,
      'fileName': stagedFile.uri.pathSegments.last,
    });

    final task = UploadTask(
      url: url.toString(),
      filename: stagedFile.uri.pathSegments.last,
      baseDirectory: BaseDirectory.applicationDocuments,
      fileField: 'file',
      fields: fields,
      headers: headers,
      metaData: metadata,
      priority: 0,
    );
    _activeTask = task;
    try {
      await _runWithRetry(
        operationName: 'upload',
        operationPath: sourcePath,
        task: task,
        onProgress: onProgress,
        action: () async {
          final result = await FileDownloader().upload(
            task,
            onProgress: (progress) {
              if (progress >= 0) onProgress((progress * 100).round(), 100);
            },
          );
          if (result.status != TaskStatus.complete) {
            throw StateError('Background upload failed: ${result.status}');
          }
          onProgress(100, 100);
        },
      );
    } finally {
      _activeTask = null;
      if (await stagedFile.exists()) await stagedFile.delete();
    }
  }

  Future<File> download({
    required Uri url,
    required String fileName,
    required Map<String, String> headers,
    required void Function(int received, int total) onProgress,
  }) async {
    final sourcePath = url.queryParameters['path'] ?? url.path;
    final metadata = _metadata({
      'sourcePath': sourcePath,
      'fileName': fileName,
      'endpoint': url.path,
    });
    final task = DownloadTask(
      url: url.toString(),
      filename: fileName,
      baseDirectory: BaseDirectory.applicationDocuments,
      headers: headers,
      metaData: metadata,
      priority: 0,
    );
    _activeTask = task;
    try {
      final savedFile = await _runWithRetry(
        operationName: 'download',
        operationPath: sourcePath,
        task: task,
        onProgress: onProgress,
        action: () async {
          final result = await FileDownloader().download(
            task,
            onProgress: (progress) {
              if (progress >= 0) onProgress((progress * 100).round(), 100);
            },
          );
          if (result.status != TaskStatus.complete) {
            throw StateError('Background download failed: ${result.status}');
          }
          return File(await task.filePath());
        },
      );
      return savedFile;
    } finally {
      _activeTask = null;
    }
  }

  Future<void> cancel() async {
    final task = _activeTask;
    if (task != null) {
      _activeTask = null;
      await FileDownloader().cancelTaskWithId(task.taskId);
    }
  }

  Future<File> _stageUploadFile(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = _safeFileName(sourceFile.path);
    final stagedFile = File(
      '${directory.path}${Platform.pathSeparator}$safeName',
    );
    if (stagedFile.path != sourceFile.path) {
      if (!await stagedFile.exists() ||
          (await stagedFile.length()) != await sourceFile.length()) {
        await sourceFile.copy(stagedFile.path);
      }
    }
    return stagedFile;
  }

  Future<T> _runWithRetry<T>({
    required String operationName,
    required String operationPath,
    required Task task,
    required Future<T> Function() action,
    required void Function(int sent, int total) onProgress,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        if (attempt >= _maxAttempts) {
          rethrow;
        }

        debugPrint(
          '[BackgroundFileTransferService] $operationName retrying after failure '
          'for $operationPath (attempt $attempt/${_maxAttempts - 1})',
        );
        onProgress(0, 100);
        if (task is DownloadTask) {
          await FileDownloader().cancelTaskWithId(task.taskId);
        }
      }
    }

    throw lastError ?? StateError('Transfer failed for $operationName');
  }

  String _metadata(Map<String, String> values) => jsonEncode(values);

  String _safeFileName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      return 'localbridge-transfer-file';
    }
    return fileName;
  }
}
