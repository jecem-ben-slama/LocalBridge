import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/shortcut.dart';


class ShortcutsBar extends StatelessWidget {
  final List<PcShortcut> shortcuts;
  final String? currentPath;
  final ValueChanged<PcShortcut> onTap;
  final ValueChanged<PcShortcut> onLongPress;
  final VoidCallback onAddPressed;

  const ShortcutsBar({
    super.key,
    required this.shortcuts,
    required this.currentPath,
    required this.onTap,
    required this.onLongPress,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: shortcuts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == shortcuts.length) {
            return _AddShortcutChip(onTap: onAddPressed, colors: colors);
          }
          final shortcut = shortcuts[index];
          final selected = shortcut.path == currentPath;
          return _ShortcutChip(
            shortcut: shortcut,
            selected: selected,
            colors: colors,
            onTap: () => onTap(shortcut),
            onLongPress: () => onLongPress(shortcut),
          );
        },
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final PcShortcut shortcut;
  final bool selected;
  final dynamic colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ShortcutChip({
    required this.shortcut,
    required this.selected,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary : colors.card.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : colors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                shortcut.icon.data,
                size: 15,
                color: selected ? colors.darkest : colors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                shortcut.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.darkest : colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddShortcutChip extends StatelessWidget {
  final VoidCallback onTap;
  final dynamic colors;
  const _AddShortcutChip({required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.borderSoft,
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(Icons.add_rounded, size: 18, color: colors.muted),
        ),
      ),
    );
  }
}
