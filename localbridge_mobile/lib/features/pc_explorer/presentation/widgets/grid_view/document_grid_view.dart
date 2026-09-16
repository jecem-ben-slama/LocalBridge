import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/document.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/grid_view/document_grid_tile.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/services/document_action_handler.dart';

class DocumentGridView extends StatelessWidget {
  final List<Document> files;
  final DocumentActionHandler actions;
  final Map<String, String>? headers;
  final bool isTransferBusy;
  final Function(Document) onQuickPinFolder;

  const DocumentGridView({
    super.key,
    required this.files,
    required this.actions,
    required this.headers,
    required this.isTransferBusy,
    required this.onQuickPinFolder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return DocumentGridTile(
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
