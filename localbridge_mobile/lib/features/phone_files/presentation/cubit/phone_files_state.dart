/// Sentinel so `copyWith` can tell "error not passed, keep the current
/// one" apart from "error explicitly passed as null, clear it" — a
/// plain `error ?? this.error` can't make that distinction, and without
/// it, any copyWith call that forgets to pass `error` silently wipes an
/// existing one (this used to happen every time the server-status
/// stream ticked, unrelated to any error).
const _unset = Object();

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
    Object? error = _unset,
  }) {
    return PhoneFilesState(
      isSending: isSending ?? this.isSending,
      isServerBusy: isServerBusy ?? this.isServerBusy,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      isWebConnected: isWebConnected ?? this.isWebConnected,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}
