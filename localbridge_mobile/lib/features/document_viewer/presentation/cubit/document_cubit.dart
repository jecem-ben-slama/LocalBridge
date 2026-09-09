import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/usecases/load_directory.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepository _repository;
  final LoadDirectory _loadDirectory;

  DocumentCubit(this._repository, this._loadDirectory)
    : super(const DocumentState());

  Map<String, String> get headers => _repository.headers;

  String getThumbnailUrl(String path) => _repository.getThumbnailUrl(path);

  String getDownloadUrl(String path) => _repository.getDownloadUrl(path);

  Future<List<Document>> loadDirectory([String? path]) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final documents = await _loadDirectory(path);
      emit(DocumentState(documents: documents));
      return documents;
    } catch (error) {
      emit(DocumentState(error: error));
      rethrow;
    }
  }

  Future<void> load([String? path]) async {
    await loadDirectory(path);
  }

  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  }) => _repository.uploadFile(
    currentPath: currentPath,
    file: file,
    onProgress: onProgress,
  );

  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) => _repository.downloadToLocation(path, fileName, onProgress: onProgress);
}
