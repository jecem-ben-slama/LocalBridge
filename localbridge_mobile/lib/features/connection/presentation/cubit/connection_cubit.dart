import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_pc_connectivity.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  final CheckPcConnectivity _checkPcConnectivity;
  Timer? _timer;

  ConnectionCubit(this._checkPcConnectivity) : super(const ConnectionState());

  void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    // 1. Guard against executing if already closed
    if (isClosed) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final reachable = await _checkPcConnectivity();

      // 2. Guard after asynchronous execution in case close() was called mid-request
      if (isClosed) return;

      emit(
        state.copyWith(
          backendReachable: reachable,
          lastChecked: DateTime.now(),
          isLoading: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          error: error is String ? error : 'Connection check failed.',
        ),
      );
    }
  }

  Future<void> refresh() async => _check();

  @override
  Future<void> close() {
    // 3. Properly override close() to clean up active timers
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}
