import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_pc_connectivity.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  final CheckPcConnectivity _checkPcConnectivity;
  Timer? _timer;

  ConnectionCubit(this._checkPcConnectivity) : super(const ConnectionState());

  void start() {
    _check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final reachable = await _checkPcConnectivity();
      emit(
        state.copyWith(
          backendReachable: reachable,
          lastChecked: DateTime.now(),
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: error is String ? error : 'Connection check failed.',
        ),
      );
    }
  }

  Future<void> refresh() async => _check();

  void dispose() {
    _timer?.cancel();
  }
}
