import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/utlis/date_format.dart';
import 'package:localbridge_mobile/core/utlis/file_kind.dart';
import 'package:localbridge_mobile/core/utlis/file_kind_visuals.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/audio_player_page.dart';
import 'package:localbridge_mobile/features/common/presentation/pages/text_file_viewer_page.dart';
import 'package:localbridge_mobile/features/shared_files/presentation/pages/shared_pdf_viewer_page.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/entities/shared_file.dart';
import '../pages/media_viewer_page.dart';

class SharedFileTile extends StatelessWidget {
  final SharedFile file;
  final FileKind kind;

  const SharedFileTile({super.key, required this.file, required this.kind});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          splashColor: colors.primary.withValues(alpha: 0.08),
          highlightColor: colors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildLeading(colors),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: colors.mutedDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDateTime(file.modified),
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.mutedDark,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(colors) {
    const size = 52.0;

    if (kind.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(file.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBadge(
            icon: Icons.broken_image_rounded,
            bg: colors.errorSoft,
            fg: colors.error,
          ),
        ),
      );
    }
    if (kind.isVideo) {
      return _iconBadge(
        icon: iconForFileKind(FileKind.video),
        bg: colors.accentSoft,
        fg: colors.accent,
      );
    }
    if (kind.isAudio) {
      return _iconBadge(
        icon: iconForFileKind(FileKind.audio),
        bg: colors.infoSoft,
        fg: colors.info,
      );
    }
    if (kind.isPdf) {
      return _iconBadge(
        icon: iconForFileKind(FileKind.pdf),
        bg: colors.warningSoft,
        fg: colors.warning,
      );
    }
    if (kind.isText) {
      return _iconBadge(
        icon: iconForFileKind(FileKind.text),
        bg: colors.borderStrong,
        fg: colors.textSecondary,
      );
    }
    return _iconBadge(
      icon: iconForFileKind(FileKind.other),
      bg: colors.primarySoft,
      fg: colors.primary,
    );
  }

  Widget _iconBadge({
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: fg, size: 24),
    );
  }

  void _handleTap(BuildContext context) {
    if (kind.isImage || kind.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaViewerPage(file: file, isVideo: kind.isVideo),
        ),
      );
      return;
    }
    if (kind.isAudio) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioPlayerPage(title: file.name, source: file.path),
        ),
      );
      return;
    }
    if (kind.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SharedPdfViewerPage(file: file)),
      );
      return;
    }
    if (kind.isText) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TextFileViewerPage(title: file.name, filePath: file.path),
        ),
      );
      return;
    }
    OpenFilex.open(file.path);
  }
}
