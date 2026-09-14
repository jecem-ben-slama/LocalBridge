import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/shimmer.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/skeleton_box.dart';

/// Placeholder shaped like [DocumentGridTile], shown while a folder loads.
class DocumentGridTileSkeleton extends StatelessWidget {
  const DocumentGridTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.borderSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: colors.dark)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            child: Center(child: SkeletonBox(width: 46, height: 9)),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shaped like [DocumentListTile], shown while a folder loads.
class DocumentListTileSkeleton extends StatelessWidget {
  const DocumentListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
          const SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 12, width: double.infinity)),
          const SizedBox(width: 12),
          const SkeletonBox.circle(size: 20),
        ],
      ),
    );
  }
}

/// Drop-in replacement for the grid `GridView.builder` while files are
/// loading. Uses the same padding/gridDelegate as [PcExplorerTab]'s real
/// grid so the tiles land in the same spots once content arrives.
class DocumentGridSkeleton extends StatelessWidget {
  final int itemCount;

  const DocumentGridSkeleton({super.key, this.itemCount = 12});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const DocumentGridTileSkeleton(),
      ),
    );
  }
}

/// Drop-in replacement for the list `ListView.separated` while files are
/// loading. Uses the same padding/spacing as [PcExplorerTab]'s real list.
class DocumentListSkeleton extends StatelessWidget {
  final int itemCount;

  const DocumentListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) => const DocumentListTileSkeleton(),
      ),
    );
  }
}
