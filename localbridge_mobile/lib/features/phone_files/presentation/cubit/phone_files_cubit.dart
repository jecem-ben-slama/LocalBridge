import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/features/connection/domain/usecases/watch_web_connection.dart';
import 'package:localbridge_mobile/features/phone_files/domain/models/transfer_status.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/cancel_transfer.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/get_phone_server_status_stream.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/send_file_to_pc.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/start_file_upload.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/toggle_phone_server.dart';
import 'package:localbridge_mobile/features/phone_files/domain/usecases/watch_transfer_status.dart';

import 'phone_files_state.dart';

class PhoneFilesCubit extends Cubit<PhoneFilesState> {
  final GetPhoneServerStatusStream _getPhoneServerStatusStream;
  final TogglePhoneServer _togglePhoneServer;
  final SendFileToPc _sendFileToPc;
  final StartFileUpload _startFileUpload;
  final CancelTransfer _cancelTransfer;
  final WatchTransferStatus _watchTransferStatus;
  final WatchWebConnection _watchWebConnection;

  /// All of `start()`'s subscriptions live here instead of one nullable
  /// field per stream, so adding a stream (like `_watchWebConnection`,
  /// folded in below — this used to be subscribed to directly by the
  /// page instead of through the cubit) doesn't mean copy-pasting
  /// another field/cancel-check/dispose line.
  final List<StreamSubscription> _subscriptions = [];

  PhoneFilesCubit(
    this._getPhoneServerStatusStream,
    this._togglePhoneServer,
    this._sendFileToPc,
    this._startFileUpload,
    this._cancelTransfer,
    this._watchTransferStatus,
    this._watchWebConnection,
  ) : super(const PhoneFilesState());

  void start() {
    _cancelSubscriptions(); // idempotent: safe if start() is ever called twice

    _subscribe(_getPhoneServerStatusStream(), (isRunning) {
      emit(state.copyWith(isServerRunning: isRunning));
    });

    _subscribe(_watchTransferStatus(), _onTransferStatus);

    _subscribe(_watchWebConnection(), (isConnected) {
      emit(state.copyWith(isWebConnected: isConnected));
    });
  }

  void _onTransferStatus(TransferStatus transfer) {
    final isUpload = transfer.kind == 'upload';
    emit(
      state.copyWith(
        isSending: transfer.active && isUpload,
        progress: transfer.progress,
        fileName: transfer.fileName,
        // Surface a failed upload instead of just letting the UI go
        // idle with no explanation. Only report errors for uploads so
        // this doesn't leak unrelated download failures onto this page.
        error: (isUpload && transfer.error != null)
            ? _describeTransferError(transfer.error!)
            : null,
      ),
    );
  }

  String _describeTransferError(Object error) {
    final message = error.toString();
    return message.isEmpty ? 'File transfer failed.' : message;
  }

  void _subscribe<T>(Stream<T> stream, void Function(T) onData) {
    _subscriptions.add(stream.listen(onData));
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> toggleServer() async {
    if (state.isServerBusy) return;
    // Clear any stale error explicitly — this is now a deliberate reset
    // rather than the accidental side effect it used to be, since
    // `copyWith` no longer drops `error` on calls that don't mention it.
    emit(state.copyWith(isServerBusy: true, error: null));
    try {
      await _togglePhoneServer(isRunning: state.isServerRunning);
      emit(state.copyWith(isServerBusy: false));
    } catch (error) {
      emit(
        state.copyWith(
          isServerBusy: false,
          error: error is String
              ? error
              : 'Could not change phone server state.',
        ),
      );
    }
  }

  Future<void> pickAndSend() async {
    if (_startFileUpload.isBusy) return;
    final picked = await FilePicker.pickFile();
    if (picked == null || picked.path == null) return;
    final file = File(picked.path!);
    await _startFileUpload(
      fileName: picked.name,
      run: (onProgress) => _sendFileToPc(file: file, onProgress: onProgress),
    );
  }

  void cancelTransfer() {
    _cancelTransfer();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
