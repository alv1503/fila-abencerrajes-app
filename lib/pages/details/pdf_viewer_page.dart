// lib/pages/details/pdf_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body:
          const PDF(
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: false,
          ).cachedFromUrl(
            pdfUrl,
            placeholder: (progress) => Center(child: Text('$progress %')),
            errorWidget: (error) =>
                Center(child: Text('Error al carregar el PDF: $error')),
          ),
    );
  }
}
