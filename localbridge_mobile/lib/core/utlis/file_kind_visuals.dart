import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';

/// Canonical icon for each [FileKind].
///
/// Previously duplicated (with the same icon literals) in
/// `DocumentFileIcon._resolveSpec` and `SharedFileTile._buildLeading`.
/// Colors are intentionally kept out of here: PC Explorer renders bare
/// colored icons while Recently Shared renders icons on a soft-colored
/// badge, so the two screens choose their own color from [ThemeExtension]
/// while sharing this single icon mapping.
IconData iconForFileKind(FileKind kind) {
  switch (kind) {
    case FileKind.directory:
      return Icons.folder_rounded;
    case FileKind.video:
      return Icons.movie_rounded;
    case FileKind.audio:
      return Icons.music_note_rounded;
    case FileKind.image:
      return Icons.image_rounded;
    case FileKind.pdf:
      return Icons.picture_as_pdf_rounded;
    case FileKind.text:
      return Icons.description_rounded;
    case FileKind.docx:
      return Icons.article_rounded;
    case FileKind.spreadsheet:
      return Icons.table_chart_rounded;
    case FileKind.presentation:
      return Icons.slideshow_rounded;
    case FileKind.archive:
      return Icons.folder_zip_rounded;
    case FileKind.apk:
      return Icons.android_rounded;
    case FileKind.executable:
      return Icons.terminal_rounded;
    case FileKind.other:
      return Icons.insert_drive_file_rounded;
  }
}
