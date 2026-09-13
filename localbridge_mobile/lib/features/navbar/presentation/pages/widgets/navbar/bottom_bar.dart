import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/navbar/nav_item.dart';

class NavbarBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavbarBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final items = [
      NavItemData(icon: Icons.computer_rounded, label: 'PC Files'),
      NavItemData(icon: Icons.smartphone_rounded, label: 'Phone Files'),
      NavItemData(icon: Icons.history_rounded, label: 'Recent Shared'),
      NavItemData(icon: Icons.wifi_rounded, label: 'Connection'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.borderSoft.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final item = items[index];

            return NavItem(
              data: item,
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}
