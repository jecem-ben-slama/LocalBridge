import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/appbar/status_badge.dart';

class HeaderTitleRow extends StatelessWidget {
  final bool isExpanded;
  final bool isReachable;
  final bool phoneServerStatus;
  final VoidCallback onToggle;
  final VoidCallback onDisconnect;

  const HeaderTitleRow({
    super.key,
    required this.isExpanded,
    required this.isReachable,
    required this.phoneServerStatus,
    required this.onToggle,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onToggle,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/app-icon.svg',
            width: 40,
            height: 40,
            fit: BoxFit.fill,
          ),
          const SizedBox(width: 12),
          Text(
            'LocalBridge',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.mutedDark,
              size: 20,
            ),
          ),
          const Spacer(),
          // Laptop PC Connectivity Status
          StatusBadge(
            icon: Icons.laptop,
            isReachable: isReachable,
          ),
          // Phone Local Server Status
          StatusBadge(
            icon: Icons.phone_android,
            isReachable: phoneServerStatus,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
