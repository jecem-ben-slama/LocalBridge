import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/document.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/list_view/document_list_tile.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/services/document_action_handler.dart';

class DocumentListView extends StatelessWidget {
  final List<Document> files;
  final DocumentActionHandler actions;
  final Map<String, String>? headers;
  final bool isTransferBusy;
  final Function(Document) onQuickPinFolder;

  const DocumentListView({
    super.key,
    required this.files,
    required this.actions,
    required this.headers,
    required this.isTransferBusy,
    required this.onQuickPinFolder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final file = files[index];
        return DocumentListTile(
          file: file,
          thumbnailUrl: actions.thumbnailUrlFor(file),
          headers: headers!,
          onTap: () => actions.open(file),
          onLongPress: file.isDirectory ? () => onQuickPinFolder(file) : null,
          onDownload: file.isDirectory || isTransferBusy
              ? null
              : () => actions.downloadDirectly(file),
        );
      },
    );
  }
}
