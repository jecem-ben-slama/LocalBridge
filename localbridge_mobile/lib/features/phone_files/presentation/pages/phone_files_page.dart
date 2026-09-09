import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocBuilder<PhoneFilesCubit, PhoneFilesState>(
      builder: (context, state) {
        final cubit = context.read<PhoneFilesCubit>();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111C2E),
            title: const Text(
              'Phone Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      color: Colors.lightBlueAccent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Send files from your phone to the PC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a file and it will be uploaded to the connected PC.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    PhoneServerToggle(
                      isServerRunning: state.isServerRunning,
                      isServerBusy: state.isServerBusy,
                      isWebConnected: state.isWebConnected,
                      onChanged: (_) => cubit.toggleServer(),
                    ),
                    const SizedBox(height: 16),
                    if (state.isSending) ...[
                      LinearProgressIndicator(
                        value: state.progress,
                        color: Colors.lightBlueAccent,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Sending ${state.fileName ?? 'file'}...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: cubit.cancelTransfer,
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.7,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      onPressed: state.isSending ? null : cubit.pickAndSend,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        state.isSending ? 'Sending...' : 'Choose file',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
