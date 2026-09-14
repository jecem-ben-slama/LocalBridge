import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

import '../../domain/entities/document.dart';
import 'document_download_button.dart';
import 'document_thumbnail.dart';

/// One cell of PC Explorer's grid view.
///
/// Extracted from `PcExplorerTab._buildGridView`'s itemBuilder, which
/// duplicated most of this layout (and the thumbnail-vs-icon decision)
/// with `_buildListView`'s itemBuilder.
class DocumentGridTile extends StatelessWidget {
  final Document file;
  final String? thumbnailUrl;
  final Map<String, String> headers;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const DocumentGridTile({
    super.key,
    required this.file,
    required this.thumbnailUrl,
    required this.headers,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      children: [
        Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: colors.primary.withValues(alpha: 0.08),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.borderSoft),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        color: colors.dark,
                        child: DocumentThumbnail(
                          document: file,
                          imageUrl: thumbnailUrl,
                          headers: headers,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 7,
                    ),
                    child: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!file.isDirectory)
          Positioned(
            top: 6,
            right: 6,
            child: DocumentDownloadButton(
              overlayStyle: true,
              onPressed: onDownload,
            ),
          ),
      ],
    );
  }
}
