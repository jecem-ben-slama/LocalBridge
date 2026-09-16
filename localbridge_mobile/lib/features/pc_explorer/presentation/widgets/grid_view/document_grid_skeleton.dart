import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/shimmer.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/grid_view/document_grid_tile_skeleton.dart';



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

