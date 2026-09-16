import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'document.dart';

enum DocumentTypeFilter {
  all,
  images,
  videos,
  audio,
  documents,
  archives;

  String get label {
    switch (this) {
      case DocumentTypeFilter.all:
        return 'All';
      case DocumentTypeFilter.images:
        return 'Images';
      case DocumentTypeFilter.videos:
        return 'Videos';
      case DocumentTypeFilter.audio:
        return 'Audio';
      case DocumentTypeFilter.documents:
        return 'Docs';
      case DocumentTypeFilter.archives:
        return 'Archives';
    }
  }

  static const _documentKinds = {
    FileKind.pdf,
    FileKind.docx,
    FileKind.text,
    FileKind.spreadsheet,
    FileKind.presentation,
  };

  /// Folders will now only show when the filter is set to 'all'.
  bool matches(Document file) {
    if (file.isDirectory) {
      // Only return true if the active filter is 'all'
      return this == DocumentTypeFilter.all;
    }

    if (this == DocumentTypeFilter.all) return true;

    final kind = classifyFileKind(file.name);
    switch (this) {
      case DocumentTypeFilter.all:
        return true;
      case DocumentTypeFilter.images:
        return kind == FileKind.image;
      case DocumentTypeFilter.videos:
        return kind == FileKind.video;
      case DocumentTypeFilter.audio:
        return kind == FileKind.audio;
      case DocumentTypeFilter.documents:
        return _documentKinds.contains(kind);
      case DocumentTypeFilter.archives:
        return kind == FileKind.archive;
    }
  }
}

enum DocumentSortField { name, date, size, type }

class DocumentSortOption {
  final DocumentSortField field;
  final bool ascending;

  const DocumentSortOption(this.field, this.ascending);

  String get label {
    switch (field) {
      case DocumentSortField.name:
        return ascending ? 'Name (A–Z)' : 'Name (Z–A)';
      case DocumentSortField.date:
        return ascending ? 'Date (oldest)' : 'Date (newest)';
      case DocumentSortField.size:
        return ascending ? 'Size (smallest)' : 'Size (largest)';
      case DocumentSortField.type:
        return 'Type';
    }
  }

  int compare(Document a, Document b) {
    // Folders always sort before files, regardless of sort field.
    if (a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }

    int result;
    switch (field) {
      case DocumentSortField.name:
        result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
      case DocumentSortField.date:
        result = a.lastModified.compareTo(b.lastModified);
        break;
      case DocumentSortField.size:
        result = a.size.compareTo(b.size);
        break;
      case DocumentSortField.type:
        result = classifyFileKind(
          a.name,
        ).name.compareTo(classifyFileKind(b.name).name);
        break;
    }
    return ascending ? result : -result;
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentSortOption &&
      other.field == field &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}

