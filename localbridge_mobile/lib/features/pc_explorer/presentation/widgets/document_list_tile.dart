import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/document_download_button.dart';

import '../../domain/entities/document.dart';
import 'document_thumbnail.dart';

/// One row of PC Explorer's list view.
/// 
/// Extracted from `PcExplorerTab._buildListView`'s itemBuilder — see
/// [DocumentGridTile] for the equivalent grid-view extraction; both used to
/// independently decide "thumbnail vs icon" and reimplement the download
/// button.
class DocumentListTile extends StatelessWidget {
  final Document file;
  final String? thumbnailUrl;
  final Map<String, String> headers;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const DocumentListTile({
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

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        splashColor: colors.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DocumentThumbnail(
                  document: file,
                  imageUrl: thumbnailUrl,
                  headers: headers,
                  width: 40,
                  height: 40,
                  iconSize: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!file.isDirectory)
                DocumentDownloadButton(onPressed: onDownload)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.mutedDark,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
