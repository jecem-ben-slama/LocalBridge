import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/entities/shared_file.dart';

class SharedFileTile extends StatelessWidget {
  final SharedFile file;
  final bool isImage;

  const SharedFileTile({super.key, required this.file, required this.isImage});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(file.path),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, color: Colors.white54),
              ),
            )
          : const Icon(Icons.insert_drive_file, color: Colors.lightBlueAccent),
      title: Text(file.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        'Shared ${file.modified.toLocal()}',
        style: const TextStyle(color: Colors.white54),
      ),
      onTap: () => OpenFilex.open(file.path),
    );
  }
}
