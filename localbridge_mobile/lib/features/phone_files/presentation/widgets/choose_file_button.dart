import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class ChooseFileButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onPressed;

  const ChooseFileButton({super.key, required this.isSending, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: isSending ? null : onPressed,
        icon: Icon(
          isSending ? Icons.sync_rounded : Icons.add_circle_outline_rounded,
          size: 20,
        ),
        label: Text(
          isSending ? 'Sending File...' : 'Choose File',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.text,
          disabledBackgroundColor: colors.borderSoft,
          disabledForegroundColor: colors.mutedDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
