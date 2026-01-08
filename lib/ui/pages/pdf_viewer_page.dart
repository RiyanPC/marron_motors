import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            _showError('Se necesita permiso de almacenamiento para descargar');
          }
          setState(() => _isDownloading = false);
          return;
        }
      }

      // Download PDF
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }

      // Get app directory
      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      // Create filename from title
      final fileName =
          '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      setState(() => _isDownloading = false);

      if (mounted) {
        _showDownloadSuccess(filePath);
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        _showError('Error al descargar: $e');
      }
    }
  }

  void _showDownloadSuccess(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Descarga Completa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El PDF se ha descargado correctamente:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: const TextStyle(fontSize: 11),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await OpenFile.open(filePath);
              if (result.type != ResultType.done && mounted) {
                _showError('No se pudo abrir el archivo');
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('ABRIR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      // Download to temp directory for sharing
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        throw Exception('Error al obtener PDF');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Share using XFile
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: widget.title,
        text: 'Comprobante de venta',
      );
    } catch (e) {
      if (mounted) {
        _showError('Error al compartir: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _downloadPdf,
              tooltip: 'Descargar PDF',
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _sharePdf,
              tooltip: 'Compartir PDF',
            ),
          ],
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SfPdfViewer.network(
              widget.url,
              key: _pdfViewerKey,
              enableDoubleTapZooming: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  _showError('Error al cargar PDF: ${details.error}');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
