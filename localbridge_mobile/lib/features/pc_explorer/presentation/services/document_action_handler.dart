import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import 'package:localbridge_mobile/core/services/pdf_service.dart';
import 'package:localbridge_mobile/core/services/transfer_service.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/audio_player_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/image_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/pdf_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/text_file_viewer_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/video_viewer_page.dart';
import 'package:localbridge_mobile/injection_container.dart';

import '../../domain/entities/document.dart';
import '../cubit/document_cubit.dart';

/// Everything that happens after a user taps a document or asks to
/// download one: deciding which viewer (if any) to open, running the
/// download, and handing the local file off to an external app.
///
/// Extracted from `PcExplorerTab` — the switch over [FileKind] and the
/// half-dozen small "open X" methods it used to live in were routing
/// logic, not page layout, and didn't need a `BuildContext` captured in
/// a `State` field to work.
class DocumentActionHandler {
  final BuildContext Function() _context;
  final bool Function() _isMounted;
  final DocumentCubit cubit;
  final TransferService transfers;

  DocumentActionHandler({
    required BuildContext Function() context,
    required bool Function() isMounted,
    required this.cubit,
    required this.transfers,
  })  : _context = context,
        _isMounted = isMounted;

  BuildContext get _ctx => _context();

  /// Routes a tap on [file]: navigates into directories, otherwise opens
  /// the appropriate viewer (or falls back to a direct download) based
  /// on file kind.
  void open(Document file) {
    if (file.isDirectory) {
      cubit.navigateTo(file.path);
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
            headers: cubit.headers,
            onDownload: () => downloadDirectly(file),
          ),
        );
        break;
      case FileKind.audio:
        _pushStreamedViewer(
          file,
          builder: (url) => AudioPlayerPage(
            title: file.name,
            source: url,
            headers: cubit.headers,
            onDownload: () => downloadDirectly(file),
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
        downloadDirectly(file);
    }
  }

  /// Shared by every "download, then do X with the local file" flow
  /// (save to device, open the text viewer, hand off to an external app).
  void downloadThen(Document file, void Function(String localPath) onComplete) {
    transfers.startDownload(
      fileName: file.name,
      run: (onProgress) => cubit.downloadToLocation(
        file.path,
        file.name,
        onProgress: onProgress,
      ),
      onComplete: onComplete,
    );
  }

  void downloadDirectly(Document file) {
    downloadThen(file, (savedPath) {
      if (!_isMounted()) return;
      showAppFeedback(
        _ctx,
        'Downloaded successfully.',
        type: FeedbackType.success,
      );
      ScaffoldMessenger.of(_ctx).showSnackBar(
        SnackBar(
          content: Text('Saved to $savedPath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFilex.open(savedPath),
          ),
        ),
      );
    });
  }

  /// Audio and video both open a fullscreen viewer against the file's
  /// streamed download URL, with the same headers and download callback.
  void _pushStreamedViewer(
    Document file, {
    required Widget Function(String url) builder,
  }) {
    final url = cubit.getDownloadUrl(file.path);
    Navigator.of(_ctx).push(MaterialPageRoute(builder: (_) => builder(url)));
  }

  void _openInternalTextViewer(Document file) {
    downloadThen(file, (localPath) {
      if (!_isMounted()) return;
      Navigator.of(_ctx).push(
        MaterialPageRoute(
          builder: (_) =>
              TextFileViewerPage(title: file.name, filePath: localPath),
        ),
      );
    });
  }

  void _downloadAndOpenExternal(Document file) {
    downloadThen(file, (path) => OpenFilex.open(path));
  }

  void _openInternalPdfViewer(Document file) {
    final pdfUrl = cubit.getDownloadUrl(file.path);
    Navigator.of(_ctx).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          title: file.name,
          viewer: locator<PdfService>().buildNetworkViewer(
            pdfUrl,
            headers: cubit.headers,
          ),
          actionIcon: Icons.download_rounded,
          actionTooltip: 'Download',
          onAction: () {
            Navigator.of(context).pop();
            downloadDirectly(file);
          },
        ),
      ),
    );
  }

  void _showImageLightbox(Document file) {
    final imageUrl = cubit.getDownloadUrl(file.path);
    Navigator.of(_ctx).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (context, __, ___) => ImageViewerPage(
          title: file.name,
          imageProvider: NetworkImage(imageUrl, headers: cubit.headers),
          downloadDisabled: transfers.isBusy,
          onDownload: () => downloadDirectly(file),
        ),
      ),
    );
  }

  /// The thumbnail URL to show for [file], or null when it isn't an
  /// image (in which case `DocumentThumbnail` falls back to a
  /// file-kind icon).
  String? thumbnailUrlFor(Document file) {
    final isImage =
        !file.isDirectory && classifyFileKind(file.name) == FileKind.image;
    return isImage ? cubit.getThumbnailUrl(file.path) : null;
  }
}
