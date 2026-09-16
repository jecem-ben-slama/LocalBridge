import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/shared_file.dart';

abstract interface class SharedFilesLocalSource {
  Future<List<SharedFile>> listRecent();
}

class SharedFilesLocalSourceImpl implements SharedFilesLocalSource {
  @override
  Future<List<SharedFile>> listRecent() async {
    final root = Platform.isAndroid
        ? Directory('/storage/emulated/0/LocalBridge')
        : Directory('${(await _documentsPath())}/LocalBridge');
    if (!await root.exists()) return const [];

    final files = <SharedFile>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! File) continue;

      final fileName = entity.uri.pathSegments.last;

      // Skip trashed or hidden files
      if (fileName.contains('.trashed') || fileName.startsWith('.')) {
        continue;
      }

      final modified = (await entity.stat()).modified;
      files.add(
        SharedFile(
          name: fileName,
          path: entity.path,
          modified: modified,
          // Note: entity.readAsBytes is a function reference. 
          // If you need the actual file size in bytes, use: (await entity.length()).toString()
          size: await entity.length().then((len) => len.toString()),
        ),
      );
    }
    files.sort((left, right) => right.modified.compareTo(left.modified));
    return files;
  }

  Future<String> _documentsPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }
}