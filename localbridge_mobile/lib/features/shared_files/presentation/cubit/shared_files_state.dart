import '../../domain/entities/shared_file.dart';

class SharedFilesState {
  final List<SharedFile> files;
  final bool isLoading;
  final String? error;

  const SharedFilesState({
    this.files = const [],
    this.isLoading = false,
    this.error,
  });

  SharedFilesState copyWith({
    List<SharedFile>? files,
    bool? isLoading,
    String? error,
  }) {
    return SharedFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
