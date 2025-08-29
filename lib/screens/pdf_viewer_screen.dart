import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

// Solo importar en mobile
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // En web, simplemente marcamos como listo
      setState(() {
        isLoading = false;
      });
    } else {
      _downloadPdf();
    }
  }

  Future<void> _downloadPdf() async {
    if (kIsWeb) return;
    
    try {
      // Solo ejecutar en mobile
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/temp.pdf";

      await Dio().download(widget.pdfUrl, filePath);
      
      setState(() {
        localPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      print("Error descargando el PDF: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error descargando el PDF: $e')),
      );
    }
  }

  Future<void> _openPdfInNewTab() async {
    if (kIsWeb) {
      final Uri url = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visor de PDF"),
        actions: kIsWeb ? [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openPdfInNewTab,
            tooltip: 'Abrir PDF en nueva pestaña',
          ),
        ] : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb 
              ? _buildWebPdfViewer()
              : _buildMobilePdfViewer(),
    );
  }

  Widget _buildWebPdfViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Visor de PDF',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Para ver el PDF completo, haz clic en el botón de abajo\npara abrirlo en una nueva pestaña.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _openPdfInNewTab,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePdfViewer() {
    if (localPath == null) {
      return const Center(
        child: Text('Error al cargar el PDF'),
      );
    }
    
    // Solo usar PDFView en mobile
    return PDFView(
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
    );
  }
}
