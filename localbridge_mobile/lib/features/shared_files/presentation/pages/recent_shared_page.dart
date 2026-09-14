import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/state_placeholder.dart';

import '../../../../injection_container.dart';
import '../cubit/shared_files_cubit.dart';
import '../cubit/shared_files_state.dart';
import '../widgets/shared_file_skeleton_tile.dart';
import '../widgets/shared_file_tile.dart';

class RecentSharedPage extends StatelessWidget {
  const RecentSharedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SharedFilesCubit>()..load(),
      child: const _RecentSharedPageView(),
    );
  }
}

class _RecentSharedPageView extends StatelessWidget {
  const _RecentSharedPageView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SharedFilesCubit>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.darkest,
      appBar: AppBar(
        title: const Text('Recently Shared'),
        actions: [
          IconButton(
            onPressed: cubit.load,
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<SharedFilesCubit, SharedFilesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SharedFilesSkeletonList();
          }

          if (state.error != null) {
            return StatePlaceholder(
              icon: Icons.wifi_off_rounded,
              iconBackground: colors.errorSoft,
              iconColor: colors.error,
              title: 'Something went wrong',
              subtitle: state.error!,
              actionLabel: 'Try again',
              onAction: cubit.load,
            );
          }

          if (state.files.isEmpty) {
            return StatePlaceholder(
              icon: Icons.folder_open_rounded,
              iconBackground: colors.primarySoft,
              iconColor: colors.primary,
              title: 'No files shared yet',
              subtitle: 'Files sent from your PC will show up here.',
              actionLabel: 'Refresh',
              onAction: cubit.load,
            );
          }

          return RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.elevated,
            onRefresh: () async => cubit.load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.files.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      '${state.files.length} file${state.files.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                final file = state.files[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SharedFileTile(
                    file: file,
                    kind: classifyFileKind(file.name),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
