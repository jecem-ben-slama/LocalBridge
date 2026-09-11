import 'dart:async';
import 'dart:io';
import 'phone_files_state.dart';
//* Use Cases *
import '../../domain/usecases/get_phone_server_status.dart';
import '../../../connection/domain/usecases/get_web_connection_status.dart';
import '../../domain/usecases/send_file_to_pc.dart';
import '../../domain/usecases/toggle_phone_server.dart';
import '../../domain/usecases/watch_web_connection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//! refactor to useCase ==> Repo
import '../../../../core/services/transfer_service.dart';
import 'package:file_picker/file_picker.dart';

class PhoneFilesCubit extends Cubit<PhoneFilesState> {
  final TransferService _transfers;//!!!

  final GetPhoneServerStatus _getPhoneServerStatus;
  final GetWebConnectionStatus _getWebConnectionStatus;
  final TogglePhoneServer _togglePhoneServer;
  final WatchWebConnection _watchWebConnection;
  final SendFileToPc _sendFileToPc;
  Timer? _serverStateTimer;
  StreamSubscription<bool>? _webConnectionSubscription;
  bool _lastWebConnected = false;

  PhoneFilesCubit(
    this._transfers,
    this._getPhoneServerStatus,
    this._getWebConnectionStatus,
    this._togglePhoneServer,
    this._watchWebConnection,
    this._sendFileToPc,
  ) : super(const PhoneFilesState());
  //!!
  void start() {
    _transfers.addListener(_syncTransferState);
    _syncTransferState();
    emit(
      state.copyWith(
        isServerRunning: _getPhoneServerStatus(),
        isWebConnected: _getWebConnectionStatus(),
      ),
    );
    _webConnectionSubscription = _watchWebConnection().listen((connected) {
      final wasConnected = _lastWebConnected;
      _lastWebConnected = connected;
      emit(state.copyWith(isWebConnected: connected));
      if (!connected && wasConnected && state.isServerRunning) {
        // UI can react to this via state.error or an event hook if needed.
      }
    });
    _serverStateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final isRunning = _getPhoneServerStatus();
      if (isRunning != state.isServerRunning) {
        emit(state.copyWith(isServerRunning: isRunning));
      }
    });
  }
  //!!

  void _syncTransferState() {
    final transferState = _transfers.state;
    emit(
      state.copyWith(
        isSending: transferState.active && transferState.kind == 'upload',
        progress: transferState.progress,
        fileName: transferState.fileName,
      ),
    );
  }

  Future<void> toggleServer() async {
    if (state.isServerBusy) return;
    emit(state.copyWith(isServerBusy: true));
    try {
      await _togglePhoneServer(isRunning: state.isServerRunning);
      emit(
        state.copyWith(
          isServerRunning: !state.isServerRunning,
          isServerBusy: false,
        ),
      );
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
  //!!

  Future<void> pickAndSend() async {
    if (_transfers.isBusy) return;
    final picked = await FilePicker.pickFile();
    if (picked == null || picked.path == null) return;
    _transfers.startUpload(
      fileName: picked.name,
      run: (onProgress) =>
          _sendFileToPc(file: File(picked.path!), onProgress: onProgress),
    );
  }
  //!!

  void cancelTransfer() {
    _transfers.cancel();
  }

  void dispose() {
    _transfers.removeListener(_syncTransferState);
    _webConnectionSubscription?.cancel();
    _serverStateTimer?.cancel();
  }
}
