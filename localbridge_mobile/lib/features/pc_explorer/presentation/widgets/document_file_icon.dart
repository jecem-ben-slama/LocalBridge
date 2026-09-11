import 'package:flutter/material.dart';

import '../../domain/entities/document.dart';

class DocumentFileIcon extends StatelessWidget {
  final Document document;
  final double size;

  const DocumentFileIcon({super.key, required this.document, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final isVideo = _matches(r'\.(mp4|mkv|avi|mov|webm)$');
    final isPdf = _matches(r'\.pdf$');

    return Icon(
      document.isDirectory
          ? Icons.folder
          : isVideo
          ? Icons.movie
          : isPdf
          ? Icons.picture_as_pdf
          : Icons.insert_drive_file,
      size: size,
      color: document.isDirectory
          ? Colors.amber
          : isVideo
          ? Colors.purpleAccent
          : isPdf
          ? Colors.redAccent
          : Colors.blueAccent,
    );
  }

  bool _matches(String pattern) {
    return RegExp(pattern, caseSensitive: false).hasMatch(document.name);
  }
}
