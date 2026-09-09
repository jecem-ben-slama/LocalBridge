class SharedFile {
  final String name;
  final String path;
  final DateTime modified;

  const SharedFile({
    required this.name,
    required this.path,
    required this.modified,
  });
}
