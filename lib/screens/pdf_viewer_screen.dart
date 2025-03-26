import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      // Obtener directorio local para guardar temporalmente el PDF
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/temp.pdf";

      // Descargar el PDF usando Dio
      await Dio().download(widget.pdfUrl, filePath);
      
      setState(() {
        localPath = filePath;
      });
    } catch (e) {
      print("Error descargando el PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error descargando el PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visor de PDF")),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              onError: (error) {
                print(error.toString());
              },
              onPageError: (page, error) {
                print('Error en la página $page: $error');
              },
            ),
    );
  }
}
