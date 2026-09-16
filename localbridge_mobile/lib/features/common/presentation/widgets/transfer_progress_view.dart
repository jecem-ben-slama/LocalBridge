import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

enum TransferProgressStyle { card, compact }

class TransferProgressView extends StatelessWidget {
  final TransferProgressStyle style;
  final String? label;
  final String? fileName;
  final double progress;
  final Color? color; // Custom color (used mostly for the compact version)
  final VoidCallback? onCancel;

  const TransferProgressView({
    super.key,
    this.style = TransferProgressStyle.card,
    this.label,
    required this.fileName,
    required this.progress,
    this.color,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return style == TransferProgressStyle.card
        ? _buildCard(context)
        : _buildCompact(context);
  }

  Widget _buildCard(BuildContext context) {
    final colors = context.appColors;
    final activeColor = color ?? colors.primary;
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 20, color: activeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName ?? 'Transferring file...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(safeProgress * 100).toInt()}%',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 6,
              backgroundColor: colors.borderSoft,
              color: activeColor,
            ),
          ),
          const SizedBox(height: 12),
          if (onCancel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancel Transfer'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.error,
                  backgroundColor: colors.errorSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final colors = context.appColors;
    final activeColor = color ?? colors.primary;
    final safeProgress = progress.clamp(0.0, 1.0);
    final displayLabel = label != null ? '$label ' : '';

    return Container(
      color: colors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 3,
              backgroundColor: colors.borderSoft,
              valueColor: AlwaysStoppedAnimation(activeColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$displayLabel${fileName ?? 'Unknown file'} · ${(safeProgress * 100).toStringAsFixed(0)}%',
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
