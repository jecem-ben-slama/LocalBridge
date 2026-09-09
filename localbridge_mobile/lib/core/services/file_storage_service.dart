abstract interface class FileStorageService {
  Future<String> saveStream(String fileName, Stream<List<int>> bytes);

  Future<String> saveStreamWithPicker(String fileName, Stream<List<int>> bytes);
}
