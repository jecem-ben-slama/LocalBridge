import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
// Use Cases Import
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/download_file.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/fetch_document_data.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/usecases/upload_file.dart';
import '../../domain/usecases/load_directory.dart';
// Related Files
import '../../domain/entities/document_filter_sort.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final LoadDirectory _loadDirectory;
  final UploadFile _uploadFile;
  final DownloadFile _downloadFile;
  final FetchDocumentData _documentData;

  /// Guards against a slow request resolving after a newer one has
  /// already replaced it (e.g. tapping into a folder, then immediately
  /// tapping into another before the first response lands).
  int _requestVersion = 0;

  DocumentCubit(
    this._loadDirectory,
    this._uploadFile,
    this._downloadFile,
    this._documentData,
  ) : super(const DocumentState());

  Map<String, String> get headers => _documentData.headers;
  String getThumbnailUrl(String path) => _documentData.getThumbnailUrl(path);
  String getDownloadUrl(String path) => _documentData.getDownloadUrl(path);

  /// Loads [path] without touching the back-stack. Used for the initial
  /// load; for user-driven navigation use [navigateTo]/[navigateBack].
  Future<void> load([String? path]) =>
      _load(path, pathHistory: state.pathHistory);

  /// Jumps to [path], pushing the current location onto the back stack.
  /// Shared by breadcrumb taps and shortcut taps — both are "go straight
  /// to this location" actions, just with different sources for [path].
  Future<void> navigateTo(String? path) async {
    if (path == state.currentPath) return;
    final history = [...state.pathHistory, state.currentPath];
    await _load(path, pathHistory: history);
  }

  /// Pops the back stack and reloads the previous directory. Returns
  /// false and does nothing if there's nowhere to go back to, so a
  /// `PopScope` caller knows whether it handled the gesture.
  Future<bool> navigateBack() async {
    if (state.pathHistory.isEmpty) return false;
    final history = [...state.pathHistory];
    final previous = history.removeLast();
    await _load(previous, pathHistory: history);
    return true;
  }

  Future<void> refresh() =>
      _load(state.currentPath, pathHistory: state.pathHistory);

  Future<void> _load(
    String? path, {
    required List<String?> pathHistory,
  }) async {
    final requestVersion = ++_requestVersion;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final documents = await _loadDirectory(path);
      if (requestVersion != _requestVersion) return;
      emit(DocumentState(
        documents: documents.where((f) => !_isHiddenFile(f.name)).toList(),
        currentPath: path,
        pathHistory: pathHistory,
        searchQuery: state.searchQuery,
        typeFilter: state.typeFilter,
        sortOption: state.sortOption,
        isGridView: state.isGridView,
      ));
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      emit(state.copyWith(isLoading: false, error: error));
    }
  }

  bool _isHiddenFile(String name) =>
      name.startsWith('.') || name.toLowerCase() == '.files';

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));
  void clearSearch() => emit(state.copyWith(searchQuery: ''));
  void setTypeFilter(DocumentTypeFilter filter) =>
      emit(state.copyWith(typeFilter: filter));
  void setSortOption(DocumentSortOption option) =>
      emit(state.copyWith(sortOption: option));
  void setGridView(bool isGridView) =>
      emit(state.copyWith(isGridView: isGridView));

  /// Uploads [file] to the current directory. Returns the future from
  /// the use case directly so callers (e.g. TransferService) correctly
  /// await completion instead of resolving as soon as the call starts.
  Future<void> uploadFile({
    required File file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _uploadFile.upload(state.currentPath, file, onProgress);
  }

  Future<String> downloadToLocation(
    String path,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) =>
      _downloadFile.downloadToLocation(path, fileName, onProgress: onProgress);
}
