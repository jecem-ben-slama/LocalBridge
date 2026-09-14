import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'package:localbridge_mobile/core/utlis/file_kind_visuals.dart';

import '../../domain/entities/document.dart';

class DocumentFileIcon extends StatelessWidget {
  final Document document;
  final double size;

  const DocumentFileIcon({super.key, required this.document, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final kind =
        classifyFileKind(document.name, isDirectory: document.isDirectory);

    return Icon(iconForFileKind(kind), size: size, color: _colorFor(kind, colors));
  }

  Color _colorFor(FileKind kind, colors) {
    switch (kind) {
      case FileKind.directory:
        return colors.warning;
      case FileKind.video:
        return colors.accent;
      case FileKind.audio:
        return colors.info;
      case FileKind.image:
        return colors.success;
      case FileKind.pdf:
        return colors.warning;
      case FileKind.text:
        return colors.textSecondary;
      case FileKind.docx:
        return colors.info;
      case FileKind.spreadsheet:
        return colors.success;
      case FileKind.presentation:
        return colors.warning;
      case FileKind.archive:
        return colors.muted;
      case FileKind.apk:
        return colors.success;
      case FileKind.executable:
        return colors.mutedDark;
      case FileKind.other:
        return colors.primary;
    }
  }
}
