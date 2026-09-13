/* import 'package:localbridge_mobile/core/services/transfer_service.dart';

class TransferFile {
  final TransferService _transfers;
   final WatchWebConnection _watchWebConnection;

  final GetPhoneServerStatus _getPhoneServerStatus;
  final GetWebConnectionStatus _getWebConnectionStatus;
  final TogglePhoneServer _togglePhoneServer;
  TransferFile(this._transfers,this._getPhoneServerStatus,this._getWebConnectionStatus,this._togglePhoneServer);
  
  void
    start() {
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
    
  
}
 */