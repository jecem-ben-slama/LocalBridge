// domain/repositories/transfer_repository.dart
import '../models/transfer_status.dart';

abstract class TransferRepository {
  Stream<TransferStatus> watchTransferStatus();
  bool get isBusy;
  Future<void> startUpload({
    required String fileName,
    required Future<void> Function(
      void Function(int sent, int total) onProgress,
    )
    run,
  });
  void cancel();
}
