import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../injection_container.dart';
import '../../../connection/domain/usecases/watch_web_connection.dart';
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

class _PhoneFilesPageView extends StatefulWidget {
  const _PhoneFilesPageView();

  @override
  State<_PhoneFilesPageView> createState() => _PhoneFilesPageViewState();
}

class _PhoneFilesPageViewState extends State<_PhoneFilesPageView> {
  late final Stream<bool> _webConnectionChanges;
  late StreamSubscription<bool> _webConnectionSubscription;
  bool _isWebConnected = false;

  @override
  void initState() {
    super.initState();
    // 1. Initialize current status & stream
    _webConnectionChanges = locator<WatchWebConnection>()();

    // 2. Subscribe to connection updates directly
    _webConnectionSubscription = _webConnectionChanges.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isWebConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    // 3. Clean up stream subscription on teardown
    _webConnectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<PhoneFilesCubit, PhoneFilesState>(
      builder: (context, state) {
        final cubit = context.read<PhoneFilesCubit>();

        return Scaffold(
          backgroundColor: colors.darkest,
          appBar: AppBar(
            backgroundColor: colors.dark,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Phone Files',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: colors.borderSoft, height: 1),
            ),
          ),
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
                      // Header Card Component
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.borderSoft),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.accentSoft.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: colors.accent,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Send files from phone to PC',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select any document or media file to transfer it immediately to your desktop environment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Server Control Module (Uses real-time stream state)
                      PhoneServerToggle(
                        isServerRunning: state.isServerRunning,
                        isServerBusy: state.isServerBusy,
                        isWebConnected: _isWebConnected,
                        onChanged: (_) => cubit.toggleServer(),
                      ),
                      const SizedBox(height: 16),

                      // File Transfer Status Box
                      if (state.isSending) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.elevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    size: 20,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.fileName ?? 'Transferring file...',
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
                                    '${((state.progress) * 100).toInt()}%',
                                    style: TextStyle(
                                      color: colors.primary,
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
                                  value: state.progress,
                                  minHeight: 6,
                                  backgroundColor: colors.borderSoft,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: cubit.cancelTransfer,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
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
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Main Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: state.isSending ? null : cubit.pickAndSend,
                          icon: Icon(
                            state.isSending
                                ? Icons.sync_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 20,
                          ),
                          label: Text(
                            state.isSending ? 'Sending File...' : 'Choose File',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
