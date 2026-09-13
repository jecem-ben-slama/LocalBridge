import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class StatusBadge extends StatelessWidget {
  final bool isReachable;
  final double size;
  final IconData? icon;
  final Color? iconColor;

  const StatusBadge({
    super.key,
    required this.isReachable,
    this.size = 20,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = isReachable ? colors.success : colors.warning;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4), // Padding to expand tap target
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            // Centered icon overlay
            if (icon != null)
              Icon(
                icon,
                size: size * 0.6, // Scales automatically with circle size
                color: isReachable ? Colors.white : Colors.red,
              ),
          ],
        ),
      ),
    );
  }
}
