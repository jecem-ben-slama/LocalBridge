class PhoneFilesState {
  final bool isSending;
  final bool isServerBusy;
  final bool isServerRunning;
  final bool isWebConnected;
  final double progress;
  final String? fileName;
  final String? error;

  const PhoneFilesState({
    this.isSending = false,
    this.isServerBusy = false,
    this.isServerRunning = false,
    this.isWebConnected = false,
    this.progress = 0,
    this.fileName,
    this.error,
  });

  PhoneFilesState copyWith({
    bool? isSending,
    bool? isServerBusy,
    bool? isServerRunning,
    bool? isWebConnected,
    double? progress,
    String? fileName,
    String? error,
  }) {
    return PhoneFilesState(
      isSending: isSending ?? this.isSending,
      isServerBusy: isServerBusy ?? this.isServerBusy,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      isWebConnected: isWebConnected ?? this.isWebConnected,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      error: error,
    );
  }
}
