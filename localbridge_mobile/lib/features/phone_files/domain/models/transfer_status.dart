class TransferStatus {
  final bool active;
  final bool isBusy;
  final String kind;
  final double progress;
  final String? fileName;
  final Object? error;

  const TransferStatus({
    required this.active,
    required this.isBusy,
    required this.kind,
    required this.progress,
    required this.fileName,
    this.error,
  });
}
