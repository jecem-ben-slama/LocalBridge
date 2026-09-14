/// Central place for classifying a file by its extension.
///
/// Previously this logic was duplicated (with small inconsistencies, e.g.
/// missing `m4v`/`3gp`/`heic` in some copies) across `DocumentFileIcon`,
/// `PcExplorerTab`, and `RecentSharedPage`. Consolidating it here means
/// those three surfaces can never drift out of sync again, and callers like
/// `SharedFileTile` can key their UI off a single enum instead of five
/// separate booleans.
enum FileKind {
  directory,
  image,
  video,
  audio,
  pdf,
  text,
  docx,
  spreadsheet,
  presentation,
  archive,
  apk,
  executable,
  other,
}

FileKind classifyFileKind(String name, {bool isDirectory = false}) {
  if (isDirectory) return FileKind.directory;

  bool matches(String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(name);

  if (matches(r'\.(mp4|mkv|avi|mov|webm|m4v|3gp)$')) return FileKind.video;
  if (matches(r'\.(mp3|m4a|wav|flac|aac|ogg|opus)$')) return FileKind.audio;
  if (matches(r'\.(png|jpe?g|gif|webp|bmp|heic)$')) return FileKind.image;
  if (matches(r'\.pdf$')) return FileKind.pdf;
  if (matches(r'\.(txt|md|log|json|yaml|yml|xml|csv|ini|conf)$')) {
    return FileKind.text;
  }
  if (matches(r'\.(docx?|rtf|odt)$')) return FileKind.docx;
  if (matches(r'\.(xlsx?|ods)$')) return FileKind.spreadsheet;
  if (matches(r'\.(pptx?|odp)$')) return FileKind.presentation;
  if (matches(r'\.(zip|rar|7z|tar|gz)$')) return FileKind.archive;
  if (matches(r'\.apk$')) return FileKind.apk;
  if (matches(r'\.(exe|msi|dmg|deb)$')) return FileKind.executable;

  return FileKind.other;
}

extension FileKindX on FileKind {
  bool get isDirectory => this == FileKind.directory;
  bool get isImage => this == FileKind.image;
  bool get isVideo => this == FileKind.video;
  bool get isAudio => this == FileKind.audio;
  bool get isPdf => this == FileKind.pdf;
  bool get isText => this == FileKind.text;
  bool get isDocx => this == FileKind.docx;
}
