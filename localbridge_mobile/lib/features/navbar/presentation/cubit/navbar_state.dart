class NavbarState {
  final int currentIndex;
  final bool pcReachable;
  final bool isServerRunning;
  final String? error;

  const NavbarState({
    this.currentIndex = 0,
    this.pcReachable = false,
    this.isServerRunning = false,
    this.error,
  });

  NavbarState copyWith({
    int? currentIndex,
    bool? pcReachable,
    bool? isServerRunning,
    String? error,
  }) {
    return NavbarState(
      currentIndex: currentIndex ?? this.currentIndex,
      pcReachable: pcReachable ?? this.pcReachable,
      isServerRunning: isServerRunning ?? this.isServerRunning,
      error: error,
    );
  }
}
