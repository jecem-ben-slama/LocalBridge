import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
// Use Cases Import
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/download_file.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/fetch_document_data.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/upload_file.dart';
import '../../domain/usecases/load_directory.dart';
// Related Files
import '../../domain/entities/document.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final LoadDirectory _loadDirectory;
  final UploadFile _uploadFile;
  final DownloadFile _downloadFile;
  final FetchDocumentData _documentData;

  DocumentCubit(
    this._loadDirectory,
    this._uploadFile,
    this._downloadFile,
    this._documentData,
  ) : super(const DocumentState());

  Map<String, String> get headers => _documentData.headers;
  String getThumbnailUrl(String path) => _documentData.getThumbnailUrl(path);
  String getDownloadUrl(String path) => _documentData.getDownloadUrl(path);

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

  Future<void> load([String? path]) => loadDirectory(path);

  /// Uploads [file] to [currentPath] on the PC. Returns the future from
  /// the use case directly so callers (e.g. TransferService) correctly
  /// await completion instead of resolving as soon as the call starts.
  Future<void> uploadFile({
    required String? currentPath,
    required File file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _uploadFile.upload(currentPath, file, onProgress);
  }

  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) =>
      _downloadFile.downloadToLocation(path, fileName, onProgress: onProgress);
}
