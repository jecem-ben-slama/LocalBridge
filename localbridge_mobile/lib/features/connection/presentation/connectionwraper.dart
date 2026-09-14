import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localbridge_mobile/injection_container.dart';
import '../../connection/domain/usecases/watch_web_connection.dart';
import '../../connection/domain/usecases/disconnect_session.dart';
import '../../connection/presentation/pages/qr_scanner_page.dart';

class ConnectionListenerWrapper extends StatefulWidget {
  final Widget child;

  const ConnectionListenerWrapper({super.key, required this.child});

  @override
  State<ConnectionListenerWrapper> createState() =>
      _ConnectionListenerWrapperState();
}

class _ConnectionListenerWrapperState extends State<ConnectionListenerWrapper> {
  StreamSubscription<bool>? _subscription;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _initListener();
  }

  void _initListener() {
    // Only listen to real-time events. Skip the premature upfront check on startup
    // to prevent blocking the user while the app initializes.
    _subscription = locator<WatchWebConnection>()().listen((isConnected) async {
      if (!isConnected && mounted && !_isDialogShowing) {
        await _handleSessionDeath();
      } else if (isConnected && mounted && _isDialogShowing) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isDialogShowing = false);
      }
    });
  }

  Future<void> _handleSessionDeath() async {
    if (!mounted || _isDialogShowing) return;

    try {
      await locator<DisconnectSession>()();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Session Died'),
          content: const Text(
            'The connection to the PC session has been lost. Access is blocked until you reconnect.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() => _isDialogShowing = false);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  (_) => false,
                );
              },
              child: const Text('Scan to Reconnect'),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isDialogShowing = false);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isDialogShowing)
          Positioned.fill(
            child: ModalBarrier(
              color: Colors.black.withValues(alpha: 0.8),
              dismissible: false,
            ),
          ),
      ],
    );
  }
}
