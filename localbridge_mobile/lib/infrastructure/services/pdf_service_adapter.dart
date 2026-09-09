import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/services/pdf_service.dart';

class PdfServiceAdapter implements PdfService {
  @override
  Widget buildViewer(String filePath) => SfPdfViewer.file(File(filePath));
}
