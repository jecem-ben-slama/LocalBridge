import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/pdf_viewer_page.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/services/pdf_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/shared_file.dart';

/// Views a PDF already saved locally on-device (shared files live on disk,
/// unlike PC Explorer's files which are streamed over the network).
class SharedPdfViewerPage extends StatelessWidget {
  final SharedFile file;

  const SharedPdfViewerPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return PdfViewerPage(
      title: file.name,
      viewer: locator<PdfService>().buildViewer(file.path),
      actionIcon: Icons.open_in_new_rounded,
      actionTooltip: 'Open with another app',
      onAction: () => OpenFilex.open(file.path),
    );
  }
}
