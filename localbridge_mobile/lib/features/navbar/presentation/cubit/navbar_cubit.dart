import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../connection/domain/usecases/check_pc_connectivity.dart';
import '../../../phone_files/domain/usecases/disconnect_phone_session.dart';
import '../../../phone_files/domain/usecases/get_phone_server_status.dart';
import 'navbar_state.dart';

class NavbarCubit extends Cubit<NavbarState> {
  final CheckPcConnectivity _checkPcConnectivity;
  final GetPhoneServerStatus _getPhoneServerStatus;
  final DisconnectPhoneSession _disconnectPhoneSession;
  Timer? _statusTimer;

  NavbarCubit(
    this._checkPcConnectivity,
    this._getPhoneServerStatus,
    this._disconnectPhoneSession,
  ) : super(const NavbarState());

  void start() {
    _refreshStatus();
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshStatus(),
    );
  }

  Future<void> _refreshStatus() async {
    try {
      final reachable = await _checkPcConnectivity();
      emit(
        state.copyWith(
          pcReachable: reachable,
          isServerRunning: _getPhoneServerStatus(),
          error: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: error is String ? error : 'Connection status unavailable.',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _disconnectPhoneSession();
      emit(state.copyWith(error: null));
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

  void dispose() {
    _statusTimer?.cancel();
  }
}
