import 'dart:async';
import '../../domain/models/transfer_status.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../../../core/services/transfer_service.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferService _transferService;

  TransferRepositoryImpl(this._transferService);

  @override
  bool get isBusy => _transferService.isBusy;

  @override
  Stream<TransferStatus> watchTransferStatus() {
    late StreamController<TransferStatus> controller;

    void listener() {
      final state = _transferService.state;
      controller.add(
        TransferStatus(
          active: state.active,
          isBusy: _transferService.isBusy,
          kind: state.kind ?? 'none', // Fallback value when kind is null
          progress: state.progress,
          fileName: state.fileName,
        ),
      );
    }

    controller = StreamController<TransferStatus>.broadcast(
      onListen: () {
        _transferService.addListener(listener);
        listener(); // Emit initial state immediately
      },
      onCancel: () {
        _transferService.removeListener(listener);
      },
    );

    return controller.stream;
  }

  @override
  Future<void> startUpload({
    required String fileName,
    required Future<void> Function(
      void Function(int sent, int total) onProgress,
    )
    run,
  }) async {
    _transferService.startUpload(fileName: fileName, run: run);
  }

  @override
  void cancel() {
    _transferService.cancel();
  }
}
