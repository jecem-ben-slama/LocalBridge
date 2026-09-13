import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  StreamSubscription<bool>? _serverStatusSubscription;
  StreamSubscription<TransferStatus>? _transferSubscription;

  PhoneFilesCubit(
    this._getPhoneServerStatusStream,
    this._togglePhoneServer,
    this._sendFileToPc,
    this._startFileUpload,
    this._cancelTransfer,
    this._watchTransferStatus,
  ) : super(const PhoneFilesState());

  void start() {
    // 1. Reactive server status stream (handles initial state + real-time updates)
    _serverStatusSubscription?.cancel();
    _serverStatusSubscription = _getPhoneServerStatusStream().listen((isRunning) {
      emit(state.copyWith(isServerRunning: isRunning));
    });

    // 2. Active file transfer status stream
    _transferSubscription?.cancel();
    _transferSubscription = _watchTransferStatus().listen((transfer) {
      emit(
        state.copyWith(
          isSending: transfer.active && transfer.kind == 'upload',
          progress: transfer.progress,
          fileName: transfer.fileName,
        ),
      );
    });
  }

  Future<void> toggleServer() async {
    if (state.isServerBusy) return;
    emit(state.copyWith(isServerBusy: true));
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
    _serverStatusSubscription?.cancel();
    _transferSubscription?.cancel();
    return super.close();
  }
}