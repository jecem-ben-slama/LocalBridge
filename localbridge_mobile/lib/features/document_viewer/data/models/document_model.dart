import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  DocumentModel({
    required super.name,
    required super.path,
    required super.isDirectory,
    required super.size,
    required super.lastModified,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      isDirectory: json['isDirectory'] ?? false,
      size: json['size'] ?? 0,
      lastModified: json['lastModified'] ?? 0,
    );
  }
}
