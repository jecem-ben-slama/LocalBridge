import 'package:flutter/material.dart';
import 'dart:io';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/audio_player_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/image_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/pdf_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/text_file_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/video_viewer_page.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/document.dart';
import 'package:localbridge_mobile/injection_container.dart';
// Widgets
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_explorer_header.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_grid_tile.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_list_tile.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_tile_skeletons.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_transfer_progress.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/empty_document_state.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/cubit/document_cubit.dart';
// Package Services
import 'package:localbridge_mobile/core/services/pdf_service.dart';
import 'package:localbridge_mobile/core/services/transfer_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<Document> _files = [];
  String? _currentPath;
  String _searchQuery = '';
  final List<String?> _pathHistory = [];
  bool _isLoading = false;
  bool _isGridView = true;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadingFileName = '';

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadingFileName = '';
  int _directoryRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _transfers.addListener(_refreshTransferState);
    _refreshTransferState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transfers.removeListener(_refreshTransferState);
    super.dispose();
  }

  void _refreshTransferState() {
    final state = _transfers.state;
    if (!mounted) return;
    setState(() {
      _isUploading = state.active && state.kind == 'upload';
      _uploadProgress = state.progress;
      _uploadingFileName = state.fileName ?? '';
      _isDownloading = state.active && state.kind == 'download';
      _downloadProgress = state.progress;
      _downloadingFileName = state.fileName ?? '';
    });
  }

  List<Document> get _visibleFiles {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _files;
    return _files
        .where((file) => file.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _loadFiles([String? path]) async {
    if (!mounted) return;
    final requestVersion = ++_directoryRequestVersion;
    setState(() => _isLoading = true);

    try {
      final files = await _cubit.loadDirectory(path);
      if (!mounted || requestVersion != _directoryRequestVersion) return;
      setState(() {
        _files = files.where((file) => !_isHiddenFile(file.name)).toList();
        _currentPath = path;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _directoryRequestVersion) return;
      setState(() => _isLoading = false);
      showAppFeedback(
        context,
        userMessage(e, fallback: 'Could not load PC files.'),
        type: FeedbackType.error,
      );
    }
  }

  bool _isHiddenFile(String name) =>
      name.startsWith('.') || name.toLowerCase() == '.files';

  Future<void> _uploadFile() async {
    if (_transfers.isBusy) return;
    final PlatformFile? picked = await FilePicker.pickFile();
    if (picked == null || picked.path == null) return;
    final file = File(picked.path!);
    _transfers.startUpload(
      fileName: picked.name,
      run: (onProgress) => _cubit.uploadFile(
        currentPath: _currentPath,
        file: file,
        onProgress: onProgress,
      ),
    );
  }

  Future<void> _downloadDirectly(Document file) async {
    _transfers.startDownload(
      fileName: file.name,
      run: (onProgress) => _cubit.downloadToLocation(
        file.path,
        file.name,
        onProgress: onProgress,
      ),
      onComplete: (savedPath) {
        if (!mounted) return;
        showAppFeedback(
          context,
          'Downloaded successfully.',
          type: FeedbackType.success,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $savedPath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(savedPath),
            ),
          ),
        );
      },
    );
  }

  bool _navigateBack() {
    if (_pathHistory.isNotEmpty) {
      _loadFiles(_pathHistory.removeLast());
      return true;
    }
    return false;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  String get _locationLabel =>
      _currentPath == null || _currentPath!.isEmpty ? 'This PC' : _currentPath!;

  void _onNodeTap(Document file) {
    if (file.isDirectory) {
      _pathHistory.add(_currentPath);
      _loadFiles(file.path);
      return;
    }

    switch (classifyFileKind(file.name)) {
      case FileKind.image:
        _showImageLightbox(file);
        break;
      case FileKind.video:
        _pushStreamedViewer(
          file,
          builder: (url) => VideoViewerPage(
            title: file.name,
            source: url,
            headers: _cubit.headers,
            onDownload: () => _downloadDirectly(file),
          ),
        );
        break;
      case FileKind.audio:
        _pushStreamedViewer(
          file,
          builder: (url) => AudioPlayerPage(
            title: file.name,
            source: url,
            headers: _cubit.headers,
            onDownload: () => _downloadDirectly(file),
          ),
        );
        break;
      case FileKind.pdf:
        _openInternalPdfViewer(file);
        break;
      case FileKind.text:
        _openInternalTextViewer(file);
        break;
      case FileKind.docx:
        _downloadAndOpenExternal(file);
        break;
      default:
        _downloadDirectly(file);
    }
  }

  /// Audio and video both open a fullscreen viewer against the file's
  /// streamed download URL, with the same headers and download callback.
  /// Previously `_openInternalAudioPlayer` and `_openInternalVideoPlayer`
  /// were two near-identical methods; this is the one push helper both
  /// kinds now go through.
  void _pushStreamedViewer(
    Document file, {
    required Widget Function(String url) builder,
  }) {
    final url = _cubit.getDownloadUrl(file.path);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder(url)));
  }

  void _openInternalTextViewer(Document file) {
    _transfers.startDownload(
      fileName: file.name,
      run: (onProgress) => _cubit.downloadToLocation(
        file.path,
        file.name,
        onProgress: onProgress,
      ),
      onComplete: (localPath) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TextFileViewerPage(title: file.name, filePath: localPath),
          ),
        );
      },
    );
  }

  void _downloadAndOpenExternal(Document file) {
    _transfers.startDownload(
      fileName: file.name,
      run: (onProgress) => _cubit.downloadToLocation(
        file.path,
        file.name,
        onProgress: onProgress,
      ),
      onComplete: (path) => OpenFilex.open(path),
    );
  }

  void _openInternalPdfViewer(Document file) {
    final pdfUrl = _cubit.getDownloadUrl(file.path);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          title: file.name,
          viewer: locator<PdfService>()
              .buildNetworkViewer(pdfUrl, headers: _cubit.headers),
          actionIcon: Icons.download_rounded,
          actionTooltip: 'Download',
          onAction: () {
            Navigator.of(context).pop();
            _downloadDirectly(file);
          },
        ),
      ),
    );
  }

  void _showImageLightbox(Document file) {
    final imageUrl = _cubit.getDownloadUrl(file.path);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (context, __, ___) => ImageViewerPage(
          title: file.name,
          imageProvider: NetworkImage(imageUrl, headers: _cubit.headers),
          downloadDisabled: _transfers.isBusy,
          // ImageViewerPage's DownloadAppBarAction now pops the route
          // itself before invoking this, so we no longer pop here too.
          onDownload: () => _downloadDirectly(file),
        ),
      ),
    );
  }

  /// The thumbnail URL to show for [file], or null when it isn't an image
  /// (in which case `DocumentThumbnail` falls back to a file-kind icon).
  String? _thumbnailUrlFor(Document file) {
    final isImage = !file.isDirectory &&
        classifyFileKind(file.name) == FileKind.image;
    return isImage ? _cubit.getThumbnailUrl(file.path) : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: _pathHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: colors.darkest,
        appBar: AppBar(
          titleSpacing: 20,
          title: const Text(
            'PC Files',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          leading: _pathHistory.isNotEmpty
              ? IconButton(
                  tooltip: 'Go back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: _navigateBack,
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Refresh folder',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : () => _loadFiles(_currentPath),
            ),
            IconButton(
              tooltip: _isGridView ? 'Use list view' : 'Use grid view',
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              tooltip: 'Send to PC',
              icon: const Icon(Icons.upload_file_rounded),
              onPressed: _transfers.isBusy ? null : _uploadFile,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            DocumentExplorerHeader(
              locationLabel: _locationLabel,
              itemCount: _files.length,
              searchController: _searchController,
              searchQuery: _searchQuery,
              onClearSearch: _clearSearch,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
            ),
            if (_isUploading)
              DocumentTransferProgress(
                label: 'Uploading',
                fileName: _uploadingFileName,
                progress: _uploadProgress,
                color: colors.accent,
                onCancel: () => _transfers.cancel(),
              ),
            if (_isDownloading)
              DocumentTransferProgress(
                label: 'Downloading',
                fileName: _downloadingFileName,
                progress: _downloadProgress,
                color: colors.success,
                onCancel: () => _transfers.cancel(),
              ),
            Expanded(
              child: _isLoading
                  ? (_isGridView
                      ? const DocumentGridSkeleton()
                      : const DocumentListSkeleton())
                  : _visibleFiles.isEmpty
                  ? EmptyDocumentState(
                      isSearching: _searchQuery.trim().isNotEmpty,
                      onClearSearch: _clearSearch,
                    )
                  : RefreshIndicator(
                      color: colors.primary,
                      backgroundColor: colors.elevated,
                      onRefresh: () => _loadFiles(_currentPath),
                      child: _isGridView ? _buildGridView() : _buildListView(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _visibleFiles.length,
      itemBuilder: (context, index) {
        final file = _visibleFiles[index];
        return DocumentGridTile(
          file: file,
          thumbnailUrl: _thumbnailUrlFor(file),
          headers: _cubit.headers,
          onTap: () => _onNodeTap(file),
          onDownload:
              file.isDirectory || _transfers.isBusy ? null : () => _downloadDirectly(file),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _visibleFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final file = _visibleFiles[index];
        return DocumentListTile(
          file: file,
          thumbnailUrl: _thumbnailUrlFor(file),
          headers: _cubit.headers,
          onTap: () => _onNodeTap(file),
          onDownload:
              file.isDirectory || _transfers.isBusy ? null : () => _downloadDirectly(file),
        );
      },
    );
  }
}
