import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class DocumentTransferProgress extends StatelessWidget {
  final String label;
  final String fileName;
  final double progress;
  final Color color;
  final VoidCallback? onCancel;

  const DocumentTransferProgress({
    super.key,
    required this.label,
    required this.fileName,
    required this.progress,
    required this.color,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: colors.borderSoft,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$label $fileName · ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colors.error,
                    ),
                    label: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 12, color: colors.error),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
