import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/shimmer.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/skeleton_box.dart';

/// Placeholder shaped like [SharedFileTile], shown while shared files load.
class SharedFileSkeletonTile extends StatelessWidget {
  const SharedFileSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SkeletonBox(
            width: 52,
            height: 52,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 13, width: MediaQuery.of(context).size.width * 0.4),
                const SizedBox(height: 8),
                const SkeletonBox(height: 11, width: 90),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox.circle(size: 18),
        ],
      ),
    );
  }
}

/// Drop-in replacement for [RecentSharedPage]'s file list while it loads.
/// Uses the same outer padding and per-item spacing as the real list.
class SharedFilesSkeletonList extends StatelessWidget {
  final int itemCount;

  const SharedFilesSkeletonList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: SharedFileSkeletonTile(),
        ),
      ),
    );
  }
}
