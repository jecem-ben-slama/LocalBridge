import 'package:flutter/material.dart';

enum FeedbackType { info, success, error }

void showAppFeedback(
  BuildContext context,
  String message, {
  FeedbackType type = FeedbackType.info,
}) {
  final colors = switch (type) {
    FeedbackType.success => (Colors.greenAccent, Icons.check_circle),
    FeedbackType.error => (Colors.redAccent, Icons.error_outline),
    FeedbackType.info => (Colors.lightBlueAccent, Icons.info_outline),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            Icon(colors.$2, color: colors.$1),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
