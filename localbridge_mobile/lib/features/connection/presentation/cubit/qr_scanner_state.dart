class QrScannerState {
  final bool isConnecting;
  final bool isSuccess;
  final String? error;

  const QrScannerState({
    this.isConnecting = false,
    this.isSuccess = false,
    this.error,
  });

  QrScannerState copyWith({
    bool? isConnecting,
    bool? isSuccess,
    String? error,
  }) {
    return QrScannerState(
      isConnecting: isConnecting ?? this.isConnecting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error, // Direct overwrite allowed to nullify previous errors
    );
  }
}
