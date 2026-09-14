import 'package:flutter/widgets.dart';

abstract interface class PdfService {
  /// Renders a PDF already saved on disk at [filePath].
  Widget buildViewer(String filePath);

  /// Streams and renders a PDF directly from [url] without requiring a
  /// local download first. [headers] are attached to the request (e.g.
  /// auth tokens needed to reach the PC's file server).
  Widget buildNetworkViewer(String url, {Map<String, String>? headers});
}
