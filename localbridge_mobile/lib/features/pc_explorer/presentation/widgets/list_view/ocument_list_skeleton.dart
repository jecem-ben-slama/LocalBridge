import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/shimmer.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/list_view/document_list_tile_skeleton.dart';

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
