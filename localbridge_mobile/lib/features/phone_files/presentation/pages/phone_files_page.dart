import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/transfer_progress_view.dart';
import 'package:localbridge_mobile/features/phone_files/presentation/widgets/choose_file_button.dart';
import 'package:localbridge_mobile/features/phone_files/presentation/widgets/header_card.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../injection_container.dart';
import '../cubit/phone_files_cubit.dart';
import '../cubit/phone_files_state.dart';
import '../widgets/phone_server_toggle.dart';

class PhoneFilesPage extends StatelessWidget {
  const PhoneFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PhoneFilesCubit>()..start(),
      child: const _PhoneFilesPageView(),
    );
  }
}

class _PhoneFilesPageView extends StatelessWidget {
  const _PhoneFilesPageView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<PhoneFilesCubit, PhoneFilesState>(
      // state.error was already being computed by the cubit but never
      // read anywhere in the page — a failed upload or server toggle
      // previously just went quiet with no feedback.
      listenWhen: (previous, current) =>
          current.error != null && current.error != previous.error,
      listener: (context, state) {
        showAppFeedback(context, state.error!, type: FeedbackType.error);
      },
      builder: (context, state) {
        final cubit = context.read<PhoneFilesCubit>();

        return Scaffold(
          backgroundColor: colors.darkest,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeaderCard(),
                      const SizedBox(height: 16),
                      PhoneServerToggle(
                        isServerRunning: state.isServerRunning,
                        isServerBusy: state.isServerBusy,
                        isWebConnected: state.isWebConnected,
                        onChanged: (_) => cubit.toggleServer(),
                      ),
                      const SizedBox(height: 16),
                      if (state.isSending) ...[
                        TransferProgressView(
                          style: TransferProgressStyle.card,
                          fileName: state.fileName,
                          progress: state.progress,
                          onCancel: cubit.cancelTransfer,
                        ),
                        const SizedBox(height: 16),
                      ],
                      ChooseFileButton(
                        isSending: state.isSending,
                        onPressed: cubit.pickAndSend,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

