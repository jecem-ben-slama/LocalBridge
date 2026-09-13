import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../connection/domain/usecases/check_pc_connectivity.dart';
import '../../../connection/domain/usecases/disconnect_session.dart';
import '../../../phone_files/domain/usecases/get_phone_server_status_stream.dart';
import 'navbar_state.dart';

class NavbarCubit extends Cubit<NavbarState> {
  final CheckPcConnectivity _checkPcConnectivity;
  final GetPhoneServerStatusStream _getPhoneServerStatusStream;
  final DisconnectSession _disconnectPhoneSession;
  Timer? _timer;

  NavbarCubit(
    this._checkPcConnectivity,
    this._getPhoneServerStatusStream,
    this._disconnectPhoneSession,
  ) : super(const NavbarState());

  void start() {
    _getPhoneServerStatusStream().listen((isRunning) {
      if (!isClosed) emit(state.copyWith(isServerRunning: isRunning));
    });

    _timer?.cancel();
    _checkPc();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkPc());
  }

  Future<void> _checkPc() async {
    if (isClosed) return;
    try {
      final reachable = await _checkPcConnectivity();
      if (!isClosed) emit(state.copyWith(pcReachable: reachable, error: null));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(pcReachable: false));
    }
  }

  Future<void> disconnect() async {
    try {
      _timer?.cancel();
      await _disconnectPhoneSession();
      emit(state.copyWith(pcReachable: false));
    } catch (error) {
      emit(
        state.copyWith(
          error: error is String ? error : 'Could not disconnect.',
        ),
      );
      rethrow;
    }
  }

  void setIndex(int index) => emit(state.copyWith(currentIndex: index));

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
