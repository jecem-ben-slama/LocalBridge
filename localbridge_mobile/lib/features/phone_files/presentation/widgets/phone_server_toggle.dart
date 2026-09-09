import 'package:flutter/material.dart';

class PhoneServerToggle extends StatelessWidget {
  final bool isServerRunning;
  final bool isServerBusy;
  final bool isWebConnected;
  final ValueChanged<bool>? onChanged;

  const PhoneServerToggle({
    super.key,
    required this.isServerRunning,
    required this.isServerBusy,
    required this.isWebConnected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: isServerRunning,
      onChanged: isServerBusy ? null : onChanged,
      title: const Text('Phone server', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        !isServerRunning
            ? 'Start only while browsing phone files'
            : isWebConnected
            ? 'Connected web app can browse phone files'
            : 'Waiting for the web app to connect',
        style: const TextStyle(color: Colors.white54),
      ),
      activeThumbColor: Colors.lightBlueAccent,
      contentPadding: EdgeInsets.zero,
    );
  }
}
