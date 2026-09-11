import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/connection_repository.dart';
import 'qr_scanner_state.dart';

class QrScannerCubit extends Cubit<QrScannerState> {
  final ConnectionRepository _repository;

  QrScannerCubit(this._repository) : super(const QrScannerState());

  Future<void> pairWithQr(String qrValue) async {
    if (state.isConnecting) return;
    emit(const QrScannerState(isConnecting: true));

    try {
      await _repository.connectFromQr(qrValue);
      emit(const QrScannerState(isSuccess: true));
    } catch (error) {
      emit(QrScannerState(error: error.toString()));
    }
  }

  Future<void> pairWithCode(String pairingCode) async {
    if (state.isConnecting) return;
    emit(const QrScannerState(isConnecting: true));

    try {
      await _repository.connectWithCode(pairingCode);
      emit(const QrScannerState(isSuccess: true));
    } catch (error) {
      emit(QrScannerState(error: error.toString()));
    }
  }
}
