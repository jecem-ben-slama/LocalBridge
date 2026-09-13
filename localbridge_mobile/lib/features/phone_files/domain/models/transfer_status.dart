// domain/models/transfer_status.dart
class TransferStatus {
  final bool active;
  final bool isBusy;
  final String kind;
  final double progress;
  final String? fileName;

  const TransferStatus({
    required this.active,
    required this.isBusy,
    required this.kind,
    required this.progress,
    this.fileName,
  });
}

