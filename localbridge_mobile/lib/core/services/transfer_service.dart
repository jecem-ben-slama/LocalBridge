import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../infrastructure/services/background_file_transfer_service.dart';

class TransferState {
  final bool active;
  final String? kind;
  final String? fileName;
  final double progress;
  final Object? error;
  final bool cancelled;

  const TransferState({
    required this.active,
    required this.kind,
    required this.fileName,
    required this.progress,
    this.error,
    this.cancelled = false,
  });

  static const idle = TransferState(
    active: false,
    kind: null,
    fileName: null,
    progress: 0,
  );
}

class TransferService extends ChangeNotifier {
  final BackgroundFileTransferService _backgroundTransfers;
  TransferState _state = TransferState.idle;
  Timer? _completionResetTimer;

  TransferService(this._backgroundTransfers);

  TransferState get state => _state;
  bool get isBusy => _state.active;

  bool startUpload({
    required String fileName,
    required Future<void> Function(void Function(int sent, int total)) run,
  }) {
    if (isBusy) return false;
    _begin('upload', fileName);
    unawaited(
      _execute(() async {
        await run(_updateProgress);
      }),
    );
    return true;
  }

  bool startDownload({
    required String fileName,
    required Future<String> Function(void Function(int received, int total))
    run,
    required void Function(String path) onComplete,
  }) {
    if (isBusy) return false;
    _begin('download', fileName);
    unawaited(
      _execute(() async {
        final path = await run(_updateProgress);
        onComplete(path);
      }),
    );
    return true;
  }

  void _begin(String kind, String fileName) {
    _state = TransferState(
      active: true,
      kind: kind,
      fileName: fileName,
      progress: 0,
    );
    notifyListeners();
  }

  void _updateProgress(int completed, int total) {
    if (!isBusy || total <= 0) return;

    final nextProgress = (completed / total).clamp(0, 1).toDouble();
    if (nextProgress >= 1) {
      _completionResetTimer?.cancel();
      _state = TransferState(
        active: false,
        kind: _state.kind,
        fileName: _state.fileName,
        progress: 1,
        error: null,
        cancelled: false,
      );
      notifyListeners();
      _completionResetTimer = Timer(const Duration(milliseconds: 500), () {
        _state = TransferState.idle;
        notifyListeners();
      });
      return;
    }

    _state = TransferState(
      active: true,
      kind: _state.kind,
      fileName: _state.fileName,
      progress: nextProgress,
    );
    notifyListeners();
  }

  Future<void> _execute(Future<void> Function() operation) async {
    try {
      await operation();
      if (_state.cancelled) {
        _state = const TransferState(
          active: false,
          kind: null,
          fileName: null,
          progress: 0,
          cancelled: false,
        );
      } else {
        _state = TransferState(
          active: false,
          kind: _state.kind,
          fileName: _state.fileName,
          progress: 1,
          error: null,
          cancelled: false,
        );
      }
    } catch (error) {
      if (error.toString().contains('cancelled') || _state.cancelled) {
        _state = const TransferState(
          active: false,
          kind: null,
          fileName: null,
          progress: 0,
          cancelled: false,
        );
      } else {
        _state = TransferState(
          active: false,
          kind: _state.kind,
          fileName: _state.fileName,
          progress: _state.progress,
          error: error,
          cancelled: false,
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    if (!_state.active) return;
    _completionResetTimer?.cancel();
    _state = TransferState(
      active: false,
      kind: _state.kind,
      fileName: _state.fileName,
      progress: _state.progress,
      cancelled: true,
    );
    await _backgroundTransfers.cancel();
    notifyListeners();
  }
}
