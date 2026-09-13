import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class HeaderExpandedDetails extends StatelessWidget {
  final bool isReachable;
  final bool isServerRunning;
  final VoidCallback onDisconnect;

  const HeaderExpandedDetails({
    super.key,
    required this.isReachable,
    required this.isServerRunning,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 4, right: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colors.borderSoft.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 14),

          // 1. Host PC Session Status
          _StatusRow(
            label: 'Host PC Session',
            value: isReachable ? 'Connected' : 'Unreachable',
            color: isReachable ? colors.success : colors.warning,
            colors: colors,
          ),
          const SizedBox(height: 8),

          // 2. Phone Server Status
          _StatusRow(
            label: 'Phone Server',
            value: isServerRunning ? 'Running' : 'Stopped',
            color: isServerRunning ? colors.success : colors.muted,
            colors: colors,
          ),

          const SizedBox(height: 12),
          Text(
            'Tap below to sever the active session with your host PC.',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
              label: const Text(
                'Disconnect Device',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: colors.error.withValues(alpha: 0.12),
                foregroundColor: colors.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final dynamic colors;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
