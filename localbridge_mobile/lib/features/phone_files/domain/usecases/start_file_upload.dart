import '../repositories/transfer_repository.dart';

class StartFileUpload {
  final TransferRepository _repository;
  StartFileUpload(this._repository);

  bool get isBusy => _repository.isBusy;

  Future<void> call({
    required String fileName,
    required Future<void> Function(
      void Function(int sent, int total) onProgress,
    )
    run,
  }) async {
    return _repository.startUpload(fileName: fileName, run: run);
  }
}
