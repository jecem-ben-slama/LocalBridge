class Document {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final int lastModified;

  Document({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
  });
}
