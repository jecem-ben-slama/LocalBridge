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
      final modified = (await entity.stat()).modified;
      files.add(
        SharedFile(
          name: entity.uri.pathSegments.last,
          path: entity.path,
          modified: modified,
          //size ??
          size: entity.readAsBytes.toString()
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
