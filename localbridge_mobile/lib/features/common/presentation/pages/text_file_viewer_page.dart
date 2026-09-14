import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/app_loading_indicator.dart';

import 'state_placeholder.dart';

/// Displays the raw text contents of a local file (config, logs, notes,
/// source code, etc). Content is loaded from [filePath] on disk.
class TextFileViewerPage extends StatefulWidget {
  final String title;
  final String filePath;

  const TextFileViewerPage({
    super.key,
    required this.title,
    required this.filePath,
  });

  @override
  State<TextFileViewerPage> createState() => _TextFileViewerPageState();
}

class _TextFileViewerPageState extends State<TextFileViewerPage> {
  String? _content;
  bool _failed = false;

  static const int _maxBytes = 2 * 1024 * 1024; // 2 MB safety cap

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.filePath);
      final size = await file.length();
      if (size > _maxBytes) {
        final raf = await file.open();
        final bytes = await raf.read(_maxBytes);
        await raf.close();
        final text = String.fromCharCodes(bytes);
        if (!mounted) return;
        setState(
          () => _content =
              '$text\n\n… file truncated (too large to display in full)',
        );
        return;
      }
      final text = await file.readAsString();
      if (!mounted) return;
      setState(() => _content = text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.darkest,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(colors) {
    if (_failed) {
      return StatePlaceholder.inlineError(
        title: "Couldn't read this file",
        iconColor: colors.error,
      );
    }

    if (_content == null) {
      return const AppLoadingIndicator();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content!,
        style: TextStyle(
          color: colors.text,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
