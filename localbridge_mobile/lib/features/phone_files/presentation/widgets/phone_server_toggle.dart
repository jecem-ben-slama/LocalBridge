import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

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
    final colors = context.appColors;

    String subtitleText;
    if (!isServerRunning) {
      subtitleText = 'Start only while browsing phone files';
    } else if (isWebConnected) {
      subtitleText = 'Connected web app can browse phone files';
    } else {
      subtitleText = 'Waiting for the web app to connect';
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isServerRunning
              ? colors.primary.withValues(alpha: 0.3)
              : colors.borderSoft,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Phone Server',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isServerRunning
                            ? colors.successSoft
                            : colors.borderSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isServerRunning ? 'ACTIVE' : 'OFFLINE',
                        style: TextStyle(
                          color: isServerRunning
                              ? colors.success
                              : colors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Platform-Adaptive Switch
          Switch.adaptive(
            value: isServerRunning,
            onChanged: isServerBusy ? null : onChanged,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
