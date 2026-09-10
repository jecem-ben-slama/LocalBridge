import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/constants/app_colors.dart';

enum FeedbackType { info, success, warning, error }

void showAppFeedback(
  BuildContext context,
  String message, {
  FeedbackType type = FeedbackType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final (accentColor, softBgColor, iconData) = switch (type) {
    FeedbackType.success => (
      AppColors.success,
      AppColors.successSoft,
      Icons.check_circle_rounded,
    ),
    FeedbackType.error => (
      AppColors.error,
      AppColors.errorSoft,
      Icons.error_rounded,
    ),
    FeedbackType.warning => (
      AppColors.warning,
      AppColors.warningSoft,
      Icons.warning_rounded,
    ),
    FeedbackType.info => (
      AppColors.info,
      AppColors.infoSoft,
      Icons.info_rounded,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.elevated,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        content: Row(
          children: [
            // Styled Icon Chip
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: softBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Message Body
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
