import '../../domain/entities/document.dart';
import '../../domain/entities/document_filter_sort.dart';

/// Single source of truth for the PC Explorer screen. Previously the
/// Cubit only tracked `documents`/`isLoading`/`error` while the page's
/// `State` duplicated all of this plus path history, search, filter,
/// sort, and view-mode in its own fields — two copies of "what's on
/// screen" that could drift out of sync. Everything now lives here.
class DocumentState {
  final List<Document> documents;
  final bool isLoading;
  final Object? error;
  final String? currentPath;
  final List<String?> pathHistory;
  final String searchQuery;
  final DocumentTypeFilter typeFilter;
  final DocumentSortOption sortOption;
  final bool isGridView;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.currentPath,
    this.pathHistory = const [],
    this.searchQuery = '',
    this.typeFilter = DocumentTypeFilter.all,
    this.sortOption = const DocumentSortOption(DocumentSortField.name, true),
    this.isGridView = true,
  });

  bool get canNavigateBack => pathHistory.isNotEmpty;

  /// [documents] filtered by search + type, then sorted. Hidden files
  /// (dotfiles, the sync sentinel) never make it into [documents] in the
  /// first place — the cubit strips those out before emitting.
  List<Document> get visibleFiles {
    final query = searchQuery.trim().toLowerCase();
    final result = documents.where((file) {
      final matchesQuery =
          query.isEmpty || file.name.toLowerCase().contains(query);
      final matchesFilter = typeFilter.matches(file);
      return matchesQuery && matchesFilter;
    }).toList();
    result.sort(sortOption.compare);
    return result;
  }

  /// For simple field tweaks (search/filter/sort/view/loading/error)
  /// that don't change [currentPath] or [pathHistory]. Path changes are
  /// built as a fresh [DocumentState] in the cubit instead, since a
  /// nullable `currentPath` can't be distinguished from "unchanged" via
  /// the usual `??` copyWith pattern.
  DocumentState copyWith({
    List<Document>? documents,
    bool? isLoading,
    Object? error,
    String? searchQuery,
    DocumentTypeFilter? typeFilter,
    DocumentSortOption? sortOption,
    bool? isGridView,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPath: currentPath,
      pathHistory: pathHistory,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      sortOption: sortOption ?? this.sortOption,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}
