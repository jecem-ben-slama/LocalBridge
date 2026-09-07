class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final int lastModified;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
  });

  factory FileNode.fromJson(Map<String, dynamic> json) {
    return FileNode(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      isDirectory: json['isDirectory'] ?? false,
      size: json['size'] ?? 0,
      lastModified: json['lastModified'] ?? 0,
    );
  }
}
