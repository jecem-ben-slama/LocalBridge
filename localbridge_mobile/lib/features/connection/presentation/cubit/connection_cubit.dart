import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_pc_connectivity.dart';
import '../../domain/usecases/watch_web_connection.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  final CheckPcConnectivity _checkPcConnectivity;
  final WatchWebConnection _watchWebConnection;
  Timer? _timer;
  StreamSubscription<bool>? _webConnectionSubscription;

  ConnectionCubit(this._checkPcConnectivity, this._watchWebConnection)
    : super(const ConnectionState());

  void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());

    _webConnectionSubscription?.cancel();
    _webConnectionSubscription = _watchWebConnection().listen((connected) {
      if (isClosed) return;
      emit(state.copyWith(isWebConnected: connected));
    });
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
    // 3. Properly override close() to clean up active timers and streams
    _timer?.cancel();
    _timer = null;
    _webConnectionSubscription?.cancel();
    _webConnectionSubscription = null;
    return super.close();
  }
}
