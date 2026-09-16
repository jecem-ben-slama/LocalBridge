import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/cubit/document_state.dart';

class PcExplorerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DocumentState state;
  final dynamic colors;
  final bool isSearchExpanded;
  final TextEditingController searchController;
  final bool isTransferBusy;
  final bool showShortcuts;
  final int shortcutsCount;

  final VoidCallback onNavigateBack;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onRefresh;
  final VoidCallback onOpenOptions;
  final VoidCallback onUploadFile;
  final VoidCallback onToggleShortcuts;

  const PcExplorerAppBar({
    super.key,
    required this.state,
    required this.colors,
    required this.isSearchExpanded,
    required this.searchController,
    required this.isTransferBusy,
    required this.showShortcuts,
    required this.shortcutsCount,
    required this.onNavigateBack,
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.onRefresh,
    required this.onOpenOptions,
    required this.onUploadFile,
    required this.onToggleShortcuts,
  });
  

String get _folderName {
    final path = state.currentPath;
    if (path == null || path.isEmpty) return 'This PC';
    final trimmed = path.replaceAll('\\', '/').trim();
    if (trimmed.isEmpty || trimmed == '/') return 'This PC';
    final segments = trimmed.split('/')..removeWhere((s) => s.isEmpty);
    return segments.isEmpty ? 'This PC' : segments.last;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 20,
      leading: isSearchExpanded
          ? null
          : (state.canNavigateBack
                ? IconButton(
                    tooltip: 'Go back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onNavigateBack,
                  )
                : null),
      title: isSearchExpanded
          ? TextField(
              controller: searchController,
              autofocus: true,
              onChanged: onSearchChanged,
              style: TextStyle(fontSize: 16, color: colors.text),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                hintText: 'Search this folder',
                hintStyle: TextStyle(color: colors.mutedDark),
                border: InputBorder.none,
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _folderName,
                key: ValueKey(_folderName),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
      actions: [
        IconButton(
          tooltip: isSearchExpanded ? 'Close search' : 'Search',
          icon: Icon(
            isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
          ),
          onPressed: onToggleSearch,
        ),
        if (!isSearchExpanded) ...[
          _ShortcutsToggleButton(
            colors: colors,
            isActive: showShortcuts,
            count: shortcutsCount,
            onPressed: onToggleShortcuts,
          ),
          IconButton(
            tooltip: 'Refresh folder',
            icon: AnimatedRotation(
              turns: state.isLoading ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: const Icon(Icons.refresh_rounded),
            ),
            onPressed: state.isLoading ? null : onRefresh,
          ),
          IconButton(
            tooltip: 'View & sort options',
            icon: const Icon(Icons.tune_rounded),
            onPressed: onOpenOptions,
          ),
          IconButton(
            tooltip: 'Send to PC',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: isTransferBusy ? null : onUploadFile,
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ShortcutsToggleButton extends StatelessWidget {
  final dynamic colors;
  final bool isActive;
  final int count;
  final VoidCallback onPressed;

  const _ShortcutsToggleButton({
    required this.colors,
    required this.isActive,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: isActive ? 'Hide shortcuts' : 'Show shortcuts',
          icon: Icon(
            isActive ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isActive ? colors.primary : colors.text,
          ),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isActive ? 1 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.darkest, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
