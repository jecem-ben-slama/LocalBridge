import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class EmptyShortcutsHint extends StatelessWidget {
  final VoidCallback onAddPressed;
  const EmptyShortcutsHint({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onAddPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: colors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              'Pin a folder for quick access',
              style: TextStyle(fontSize: 12.5, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
