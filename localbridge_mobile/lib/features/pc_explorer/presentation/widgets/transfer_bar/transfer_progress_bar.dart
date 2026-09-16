import 'package:flutter/widgets.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/services/transfer_service.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/transfer_progress_view.dart';
// Update this import to point to your new combined file:

class TransferProgressBar extends StatelessWidget {
  final TransferService transfers;

  const TransferProgressBar({super.key, required this.transfers});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: transfers,
      builder: (context, _) {
        final state = transfers.state;
        if (!state.active) return const SizedBox.shrink();

        final isUpload = state.kind == 'upload';

        return TransferProgressView(
          style: TransferProgressStyle
              .compact, // Switches it to the "thin line" view
          label: isUpload ? 'Uploading' : 'Downloading',
          fileName: state.fileName,
          progress: state.progress,
          color: isUpload ? colors.accent : colors.success,
          onCancel: transfers.cancel,
        );
      },
    );
  }
}
