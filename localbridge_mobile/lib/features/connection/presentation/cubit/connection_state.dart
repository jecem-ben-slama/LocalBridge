class ConnectionState {
  final bool backendReachable;
  final bool isWebConnected;
  final DateTime? lastChecked;
  final bool isLoading;
  final String? error;

  const ConnectionState({
    this.backendReachable = false,
    this.isWebConnected = false,
    this.lastChecked,
    this.isLoading = false,
    this.error,
  });

  ConnectionState copyWith({
    bool? backendReachable,
    bool? isWebConnected,
    DateTime? lastChecked,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionState(
      backendReachable: backendReachable ?? this.backendReachable,
      isWebConnected: isWebConnected ?? this.isWebConnected,
      lastChecked: lastChecked ?? this.lastChecked,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
