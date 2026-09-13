import '../models/transfer_status.dart';
import '../repositories/transfer_repository.dart';

class WatchTransferStatus {
  final TransferRepository _repository;
  WatchTransferStatus(this._repository);

  Stream<TransferStatus> call() => _repository.watchTransferStatus();
}
