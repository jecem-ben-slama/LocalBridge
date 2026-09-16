import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/document.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/shortcut.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/shortcuts_controller.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/shortcuts/empty_shortcuts_hint.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/list_view/ocument_list_skeleton.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/transfer_bar/transfer_progress_bar.dart';
import 'package:localbridge_mobile/injection_container.dart';
// Widgets
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/path_breadcrumbs.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/option_sheet/document_options_sheet.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/grid_view/document_grid_skeleton.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/empty_document_state.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/shortcuts/shortcuts_bar.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/shortcuts/add_shortcut_dialog.dart';
// Newly Extracted Widgets (Adjust imports based on your path structure)
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/pc_explorer_app_bar.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/grid_view/document_grid_view.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/list_view/document_list_view.dart';
// Cubit & Services
import 'package:localbridge_mobile/features/pc_explorer/presentation/cubit/document_cubit.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/cubit/document_state.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/services/document_action_handler.dart';
import 'package:localbridge_mobile/core/services/transfer_service.dart';
import 'package:file_picker/file_picker.dart';
// Shared
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';

class PcExplorerTab extends StatefulWidget {
  const PcExplorerTab({super.key});

  @override
  State<PcExplorerTab> createState() => _PcExplorerTabState();
}

class _PcExplorerTabState extends State<PcExplorerTab> {
  final DocumentCubit _cubit = locator<DocumentCubit>();
  final TransferService _transfers = locator<TransferService>();
  final ShortcutsController _shortcuts = ShortcutsController();
  final TextEditingController _searchController = TextEditingController();
  late final DocumentActionHandler _actions;

  bool _isSearchExpanded = false;
  bool _showShortcuts = true;

  @override
  void initState() {
    super.initState();
    _actions = DocumentActionHandler(
      context: () => context,
      isMounted: () => mounted,
      cubit: _cubit,
      transfers: _transfers,
    );
    _shortcuts.load();
    _cubit.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shortcuts.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _cubit.clearSearch();
  }

  void _toggleSearch() {
    final expanding = !_isSearchExpanded;
    setState(() => _isSearchExpanded = expanding);
    if (!expanding) _clearSearch();
  }

  void _toggleShortcutsVisibility() {
    setState(() => _showShortcuts = !_showShortcuts);
  }

  Future<void> _uploadFile() async {
    if (_transfers.isBusy) return;
    final picked = await FilePicker.pickFile();
    if (picked == null || picked.path == null) return;
    final file = File(picked.path!);
    _transfers.startUpload(
      fileName: picked.name,
      run: (onProgress) =>
          _cubit.uploadFile(file: file, onProgress: onProgress),
    );
  }

  Future<void> _onShortcutLongPress(PcShortcut shortcut) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove shortcut?'),
        content: Text(
          '"${shortcut.name}" will be removed from your shortcuts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) await _shortcuts.remove(shortcut.id);
  }

  Future<void> _addShortcut() async {
    final result = await AddShortcutDialog.show(
      context,
      initialPath: _cubit.state.currentPath,
    );
    if (result == null) return;
    await _shortcuts.add(
      name: result.name,
      path: result.path,
      icon: result.icon,
    );
    if (!mounted) return;
    showAppFeedback(context, 'Shortcut added.', type: FeedbackType.success);
  }

  Future<void> _quickPinFolder(Document folder) async {
    final nowPinned = await _shortcuts.togglePin(
      path: folder.path,
      name: folder.name,
    );
    if (!mounted) return;
    showAppFeedback(
      context,
      nowPinned
          ? 'Pinned "${folder.name}" to shortcuts.'
          : 'Unpinned "${folder.name}".',
      type: FeedbackType.success,
    );
  }

  void _openOptionsSheet(DocumentState state) {
    DocumentViewOptionsSheet.show(
      context,
      isGridView: state.isGridView,
      typeFilter: state.typeFilter,
      sortOption: state.sortOption,
      onGridViewChanged: _cubit.setGridView,
      onTypeFilterChanged: _cubit.setTypeFilter,
      onSortChanged: _cubit.setSortOption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _shortcuts,
      builder: (context, _) {
        return BlocConsumer<DocumentCubit, DocumentState>(
          bloc: _cubit,
          listenWhen: (previous, current) =>
              current.error != null && current.error != previous.error,
          listener: (context, state) {
            showAppFeedback(
              context,
              userMessage(state.error!, fallback: 'Could not load PC files.'),
              type: FeedbackType.error,
            );
          },
          builder: (context, state) {
            return PopScope(
              canPop: !state.canNavigateBack,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) _cubit.navigateBack();
              },
              child: Scaffold(
                backgroundColor: colors.darkest,
                appBar: PcExplorerAppBar(// 190
                  state: state,
                  colors: colors,
                  isSearchExpanded: _isSearchExpanded,
                  searchController: _searchController,
                  isTransferBusy: _transfers.isBusy,
                  showShortcuts: _showShortcuts,
                  shortcutsCount: _shortcuts.all.length,
                  onNavigateBack: _cubit.navigateBack,
                  onSearchChanged: _cubit.setSearchQuery,
                  onToggleSearch: _toggleSearch,
                  onRefresh: _cubit.refresh,
                  onOpenOptions: () => _openOptionsSheet(state),
                  onUploadFile: _uploadFile,
                  onToggleShortcuts: _toggleShortcutsVisibility,
                ),
                body: _buildBody(state, colors),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(DocumentState state, dynamic colors) {
    final visibleFiles = state.visibleFiles;

    return Column(
      children: [
        if (!_isSearchExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: PathBreadcrumbs(
              currentPath: state.currentPath,
              onSegmentTap: _cubit.navigateTo,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: !_showShortcuts
                  ? const SizedBox.shrink(key: ValueKey('shortcuts-hidden'))
                  : Padding(
                      key: const ValueKey('shortcuts-shown'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _shortcuts.all.isNotEmpty
                          ? ShortcutsBar(
                              shortcuts: _shortcuts.all,
                              currentPath: state.currentPath,
                              onTap: (shortcut) =>
                                  _cubit.navigateTo(shortcut.path),
                              onLongPress: _onShortcutLongPress,
                              onAddPressed: _addShortcut,
                            )
                          : EmptyShortcutsHint(onAddPressed: _addShortcut),
                    ),
            ),
          ),
          Divider(height: 1, color: colors.borderSoft),
        ],
        TransferProgressBar(transfers: _transfers),
        Expanded(
          child: state.isLoading
              ? (state.isGridView
                    ? const DocumentGridSkeleton()
                    : const DocumentListSkeleton())
              : visibleFiles.isEmpty
              ? EmptyDocumentState(
                  isSearching: state.searchQuery.trim().isNotEmpty,
                  onClearSearch: _clearSearch,
                )
              : RefreshIndicator(
                  color: colors.primary,
                  backgroundColor: colors.elevated,
                  onRefresh: _cubit.refresh,
                  child: state.isGridView
                      ? DocumentGridView(
                          files: visibleFiles,
                          actions: _actions,
                          headers: _cubit.headers,
                          isTransferBusy: _transfers.isBusy,
                          onQuickPinFolder: _quickPinFolder,
                        )
                      : DocumentListView(
                          files: visibleFiles,
                          actions: _actions,
                          headers: _cubit.headers,
                          isTransferBusy: _transfers.isBusy,
                          onQuickPinFolder: _quickPinFolder,
                        ),
                ),
        ),
      ],
    );
  }
}
