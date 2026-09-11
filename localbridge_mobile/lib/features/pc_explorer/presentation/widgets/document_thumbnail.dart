import 'package:flutter/material.dart';

import '../../domain/entities/document.dart';
import 'document_file_icon.dart';

class DocumentThumbnail extends StatelessWidget {
  final Document document;
  final String? imageUrl;
  final Map<String, String> headers;
  final double? width;
  final double? height;
  final BoxFit fit;

  const DocumentThumbnail({
    super.key,
    required this.document,
    required this.imageUrl,
    required this.headers,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return DocumentFileIcon(document: document);
    }

    return Image.network(
      imageUrl!,
      headers: headers,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
