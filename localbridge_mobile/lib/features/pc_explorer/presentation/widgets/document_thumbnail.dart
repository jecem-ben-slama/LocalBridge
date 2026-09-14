import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/app_loading_indicator.dart';

import '../../domain/entities/document.dart';
import 'document_file_icon.dart';

class DocumentThumbnail extends StatelessWidget {
  final Document document;
  final String? imageUrl;
  final Map<String, String> headers;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? iconSize;

  const DocumentThumbnail({
    super.key,
    required this.document,
    required this.imageUrl,
    required this.headers,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      // Previously this branch ignored width/height/fit entirely, so
      // callers that needed a sized icon (e.g. the 40x40 list row) had to
      // bypass DocumentThumbnail and call DocumentFileIcon directly. Now
      // it's sized consistently with the image and error branches below.
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: DocumentFileIcon(
            document: document,
            size: iconSize ?? 40,
          ),
        ),
      );
    }

    final colors = context.appColors;

    return Image.network(
      imageUrl!,
      headers: headers,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const AppLoadingIndicator(size: 18, strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Icon(
          Icons.broken_image_rounded,
          color: colors.mutedDark,
          size: 20,
        ),
      ),
    );
  }
}
