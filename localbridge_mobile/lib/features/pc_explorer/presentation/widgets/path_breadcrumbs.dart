import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Clickable breadcrumb trail for the current directory path, styled as
/// a standalone pill so it reads clearly on its own row.
class PathBreadcrumbs extends StatelessWidget {
  final String? currentPath;
  final ValueChanged<String?> onSegmentTap;

  const PathBreadcrumbs({
    super.key,
    required this.currentPath,
    required this.onSegmentTap,
  });

  List<_Crumb> get _crumbs {
    final path = currentPath;
    if (path == null || path.isEmpty) return [_Crumb('This PC', null)];

    final parts = path
        .replaceAll('\\', '/')
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();

    final crumbs = <_Crumb>[_Crumb('This PC', null)];
    String accumulated = '';

    for (var i = 0; i < parts.length; i++) {
      if (i == 0) {
        // Ensure root drives like 'C:' become 'C:/' so they qualify as absolute paths
        accumulated = '${parts[i]}/';
      } else {
        accumulated = '$accumulated/${parts[i]}';
      }
      crumbs.add(_Crumb(parts[i], accumulated));
    }
    return crumbs;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final crumbs = _crumbs;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.darkest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSoft),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: crumbs.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: colors.mutedDark,
          ),
        ),
        itemBuilder: (context, index) {
          final crumb = crumbs[index];
          final isLast = index == crumbs.length - 1;
          return Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isLast ? null : () => onSegmentTap(crumb.path),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.computer_rounded,
                        size: 15,
                        color: isLast ? colors.primary : colors.muted,
                      ),
                    ),
                  Text(
                    crumb.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                      color: isLast ? colors.primary : colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Crumb {
  final String label;
  final String? path;
  _Crumb(this.label, this.path);
}
