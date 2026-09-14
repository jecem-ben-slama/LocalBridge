import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/state_placeholder.dart';

class EmptyDocumentState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onClearSearch;

  const EmptyDocumentState({
    super.key,
    required this.isSearching,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return StatePlaceholder(
      icon: isSearching ? Icons.search_off_rounded : Icons.folder_open_rounded,
      iconBackground: colors.primarySoft,
      iconColor: colors.primary,
      title: isSearching ? 'No matching files' : 'This folder is empty',
      subtitle: isSearching
          ? 'Try a different name or clear the search.'
          : 'Upload a file or choose another folder.',
      actionLabel: isSearching ? 'Clear search' : null,
      actionIcon: isSearching ? Icons.clear_rounded : null,
      onAction: isSearching ? onClearSearch : null,
    );
  }
}
