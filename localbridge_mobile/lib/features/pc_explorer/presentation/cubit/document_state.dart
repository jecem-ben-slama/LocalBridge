import '../../domain/entities/document.dart';

class DocumentState {
  final List<Document> documents;
  final bool isLoading;
  final Object? error;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });

  DocumentState copyWith({
    List<Document>? documents,
    bool? isLoading,
    Object? error,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
