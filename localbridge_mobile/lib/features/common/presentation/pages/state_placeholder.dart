import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Centered icon + title + optional subtitle + optional action button.
///
/// `EmptyDocumentState` (PC Explorer) and the private `_StateMessage`
/// (Recently Shared) were the exact same layout under different names --
/// this is the one version both now build on.
///
/// [showIconBackground] additionally lets simple inline failure states
/// (e.g. "Couldn't play this audio" / "Couldn't read this file") reuse
/// this widget instead of duplicating a bare icon + text column, which is
/// what [AudioPlayerPage] and [TextFileViewerPage] used to do independently.
class StatePlaceholder extends StatelessWidget {
  final IconData icon;
  final Color? iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool showIconBackground;
  final double iconSize;

  const StatePlaceholder({
    super.key,
    required this.icon,
    this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.showIconBackground = true,
    this.iconSize = 32,
  }) : assert(
          !showIconBackground || iconBackground != null,
          'iconBackground is required when showIconBackground is true',
        );

  /// Convenience constructor for a simple inline failure message, replacing
  /// the ad-hoc "error icon + text" columns previously duplicated in
  /// [AudioPlayerPage] and [TextFileViewerPage].
  const StatePlaceholder.inlineError({
    super.key,
    required this.title,
    this.icon = Icons.error_outline_rounded,
    required this.iconColor,
  })  : iconBackground = null,
        subtitle = null,
        actionLabel = null,
        actionIcon = null,
        onAction = null,
        showIconBackground = false,
        iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            showIconBackground
                ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: iconSize),
                  )
                : Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: colors.muted, fontSize: 13.5, height: 1.4),
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: 20),
              actionIcon == null
                  ? OutlinedButton(
                      onPressed: onAction,
                      style: _actionStyle(colors),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon, size: 18, color: colors.primary),
                      label: Text(
                        actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: _actionStyle(colors),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _actionStyle(colors) => OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );
}
