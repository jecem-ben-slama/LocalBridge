import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:localbridge_mobile/features/document_viewer/domain/entities/document.dart';
import 'package:localbridge_mobile/core/services/pdf_service.dart';
import 'package:localbridge_mobile/injection_container.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/cubit/document_cubit.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/widgets/document_explorer_header.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/widgets/document_file_icon.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/widgets/document_thumbnail.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/widgets/document_transfer_progress.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/widgets/empty_document_state.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import 'package:localbridge_mobile/core/services/transfer_service.dart';

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

  bool _isImageFile(String name) => RegExp(
    r'\.(png|jpg|jpeg|gif|webp|bmp)$',
    caseSensitive: false,
  ).hasMatch(name);

  bool _isVideoFile(String name) =>
      RegExp(r'\.(mp4|mkv|avi|mov|webm)$', caseSensitive: false).hasMatch(name);

  bool _isPdfFile(String name) => name.toLowerCase().endsWith('.pdf');

  bool _isDocxFile(String name) =>
      RegExp(r'\.(docx|doc)$', caseSensitive: false).hasMatch(name);

  void _onNodeTap(Document file) {
    if (file.isDirectory) {
      _pathHistory.add(_currentPath);
      _loadFiles(file.path);
    } else if (_isImageFile(file.name)) {
      _showImageLightbox(file);
    } else if (_isVideoFile(file.name)) {
      _openInternalVideoPlayer(file);
    } else if (_isPdfFile(file.name)) {
      _openInternalPdfViewer(file);
    } else if (_isDocxFile(file.name)) {
      _downloadAndOpenExternal(file);
    } else {
      _downloadDirectly(file);
    }
  }

  void _downloadAndOpenExternal(Document file) async {
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

  void _openInternalVideoPlayer(Document file) {
    final videoUrl = _cubit.getDownloadUrl(file.path);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InternalVideoScreen(
          url: videoUrl,
          file: file,
          headers: _cubit.headers,
          onDownload: () => _downloadDirectly(file),
        ),
      ),
    );
  }

  void _openInternalPdfViewer(Document file) async {
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
            builder: (_) => InternalPdfScreen(
              filePath: localPath,
              file: file,
              onDownload: () => _downloadDirectly(file),
            ),
          ),
        );
      },
    );
  }

  void _showImageLightbox(Document file) {
    final imageUrl = _cubit.getDownloadUrl(file.path);
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            title: Text(file.name, style: const TextStyle(fontSize: 14)),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _transfers.isBusy
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _downloadDirectly(file);
                      },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                headers: _cubit.headers,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pathHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111C2E),
          titleSpacing: 20,
          title: const Text(
            'PC Files',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          leading: _pathHistory.isNotEmpty
              ? IconButton(
                  tooltip: 'Go back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Refresh folder',
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : () => _loadFiles(_currentPath),
            ),
            IconButton(
              tooltip: _isGridView ? 'Use list view' : 'Use grid view',
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              tooltip: 'Send to PC',
              icon: const Icon(Icons.upload_file),
              onPressed: _transfers.isBusy ? null : _uploadFile,
            ),
            const SizedBox(width: 8),
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
            if (_isUploading) ...[
              DocumentTransferProgress(
                label: 'Uploading',
                fileName: _uploadingFileName,
                progress: _uploadProgress,
                color: Colors.blueAccent,
                onCancel: () => _transfers.cancel(),
              ),
            ],
            if (_isDownloading) ...[
              DocumentTransferProgress(
                label: 'Downloading',
                fileName: _downloadingFileName,
                progress: _downloadProgress,
                color: Colors.greenAccent,
                onCancel: () => _transfers.cancel(),
              ),
            ],
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleFiles.isEmpty
                  ? EmptyDocumentState(
                      isSearching: _searchQuery.trim().isNotEmpty,
                      onClearSearch: _clearSearch,
                    )
                  : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
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
        final isImage = !file.isDirectory && _isImageFile(file.name);

        return Stack(
          children: [
            InkWell(
              onTap: () => _onNodeTap(file),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF172438),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Container(
                          color: const Color(0xFF0F172A),
                          child: isImage
                              ? DocumentThumbnail(
                                  document: file,
                                  imageUrl: _cubit.getThumbnailUrl(file.path),
                                  headers: _cubit.headers,
                                )
                              : DocumentFileIcon(document: file),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!file.isDirectory)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.download,
                      color: Colors.white70,
                      size: 16,
                    ),
                    onPressed: _transfers.isBusy
                        ? null
                        : () => _downloadDirectly(file),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _visibleFiles.length,
      itemBuilder: (context, index) {
        final file = _visibleFiles[index];
        final isImage = !file.isDirectory && _isImageFile(file.name);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          tileColor: index.isEven ? Colors.white.withValues(alpha: 0.02) : null,
          leading: isImage
              ? DocumentThumbnail(
                  document: file,
                  imageUrl: _cubit.getThumbnailUrl(file.path),
                  headers: _cubit.headers,
                  width: 40,
                  height: 40,
                )
              : DocumentFileIcon(document: file, size: 24),
          title: Text(
            file.name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          trailing: !file.isDirectory
              ? IconButton(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: _transfers.isBusy
                      ? null
                      : () => _downloadDirectly(file),
                )
              : null,
          onTap: () => _onNodeTap(file),
        );
      },
    );
  }
}

/// Internal Video Player Screen
class InternalVideoScreen extends StatefulWidget {
  final String url;
  final Document file;
  final Map<String, String> headers;
  final VoidCallback onDownload;

  const InternalVideoScreen({
    super.key,
    required this.url,
    required this.file,
    required this.headers,
    required this.onDownload,
  });

  @override
  State<InternalVideoScreen> createState() => _InternalVideoScreenState();
}

class _InternalVideoScreenState extends State<InternalVideoScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(widget.url),
            httpHeaders: widget.headers,
          )
          ..initialize().then((_) {
            if (mounted) {
              setState(() => _initialized = true);
              _controller.play();
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.file.name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDownload();
            },
          ),
        ],
      ),
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

/// Internal PDF Viewer Screen using syncfusion_flutter_pdfviewer
class InternalPdfScreen extends StatelessWidget {
  final String filePath;
  final Document file;
  final VoidCallback onDownload;

  const InternalPdfScreen({
    super.key,
    required this.filePath,
    required this.file,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          file.name,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              onDownload();
            },
          ),
        ],
      ),
      body: locator<PdfService>().buildViewer(filePath),
    );
  }
}
