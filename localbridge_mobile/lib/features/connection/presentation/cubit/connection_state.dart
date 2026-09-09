class ConnectionState {
  final bool backendReachable;
  final DateTime? lastChecked;
  final bool isLoading;
  final String? error;

  const ConnectionState({
    this.backendReachable = false,
    this.lastChecked,
    this.isLoading = false,
    this.error,
  });

  ConnectionState copyWith({
    bool? backendReachable,
    DateTime? lastChecked,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionState(
      backendReachable: backendReachable ?? this.backendReachable,
      lastChecked: lastChecked ?? this.lastChecked,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
