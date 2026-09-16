import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/skeleton_box.dart';

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
