import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Small download icon button used on both the grid tile (circular overlay)
/// and the list tile (trailing icon) in PC Explorer. Previously each tile
/// builder in `PcExplorerTab` reimplemented this inline.
class DocumentDownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool overlayStyle;

  const DocumentDownloadButton({
    super.key,
    required this.onPressed,
    this.overlayStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (overlayStyle) {
      return Material(
        color: colors.darkest.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.download_rounded,
            color: colors.textSecondary,
            size: 15,
          ),
          onPressed: onPressed,
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.download_rounded, color: colors.mutedDark, size: 20),
      onPressed: onPressed,
    );
  }
}
