import '../repositories/transfer_repository.dart';

class CancelTransfer {
  final TransferRepository _repository;
  CancelTransfer(this._repository);

  void call() => _repository.cancel();
}
