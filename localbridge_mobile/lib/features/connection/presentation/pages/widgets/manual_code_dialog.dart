// features/connection/presentation/pages/widgets/manual_code_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import '../../cubit/qr_scanner_cubit.dart';

void showManualCodeDialog(BuildContext parentContext) {
  showDialog<void>(
    context: parentContext,
    builder: (context) =>
        _ManualCodeDialogContent(parentContext: parentContext),
  );
}

class _ManualCodeDialogContent extends StatefulWidget {
  final BuildContext parentContext;

  const _ManualCodeDialogContent({required this.parentContext});

  @override
  State<_ManualCodeDialogContent> createState() =>
      _ManualCodeDialogContentState();
}

class _ManualCodeDialogContentState extends State<_ManualCodeDialogContent> {
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    _manualCodeController.addListener(_validateInput);
  }

  void _validateInput() {
    final isNotEmpty = _manualCodeController.text.trim().isNotEmpty;
    if (isNotEmpty != _isInputValid) {
      setState(() {
        _isInputValid = isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _manualCodeController.removeListener(_validateInput);
    _manualCodeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    if (!_isInputValid) return;
    final rawInput = _manualCodeController.text.trim();
    Navigator.of(context).pop();
    widget.parentContext.read<QrScannerCubit>().pairWithCode(rawInput);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderSoft),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.key_rounded, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Type Pairing Code',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the 6-character code displayed on your PC screen.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _manualCodeController,
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            onSubmitted: (_) => _submitCode(),
            style: TextStyle(
              color: colors.text,
              fontSize: 24,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'AB12CD',
              hintStyle: TextStyle(
                color: colors.mutedDark,
                fontSize: 22,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: colors.elevated,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: colors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isInputValid ? _submitCode : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            disabledBackgroundColor: colors.borderSoft,
            foregroundColor: colors.darkest,
            disabledForegroundColor: colors.mutedDark,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text(
            'Connect',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
