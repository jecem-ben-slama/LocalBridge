import 'package:flutter/material.dart';

/// Fullscreen PDF viewer shell. The caller supplies the already-built
/// `viewer` widget -- local file vs. streamed URL use different
/// `PdfService` methods -- and a single trailing action: "open externally"
/// for local files, "download" for streamed ones.
///
/// Replaces the near-identical `SharedPdfViewerPage` and `InternalPdfScreen`.
class PdfViewerPage extends StatelessWidget {
  final String title;
  final Widget viewer;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.viewer,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: actionTooltip,
            icon: Icon(actionIcon, color: Colors.white),
            onPressed: onAction,
          ),
        ],
      ),
      body: viewer,
    );
  }
}
