import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../cubit/shared_files_cubit.dart';
import '../cubit/shared_files_state.dart';
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

  bool _isImage(String name) => RegExp(
    r'\.(png|jpe?g|gif|webp|bmp)$',
    caseSensitive: false,
  ).hasMatch(name);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SharedFilesCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Recently Shared'),
        actions: [
          IconButton(onPressed: cubit.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<SharedFilesCubit, SharedFilesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (state.files.isEmpty) {
            return const Center(
              child: Text(
                'No files shared yet',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.files.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final file = state.files[index];
              return SharedFileTile(file: file, isImage: _isImage(file.name));
            },
          );
        },
      ),
    );
  }
}
