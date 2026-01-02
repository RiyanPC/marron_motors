import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:share_plus/share_plus.dart';

class ComprobantePreviewPage extends StatefulWidget {
  final String url;
  final String title;

  const ComprobantePreviewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ComprobantePreviewPage> createState() => _ComprobantePreviewPageState();
}

class _ComprobantePreviewPageState extends State<ComprobantePreviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF525659))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

    // Configurar para que auto-ajuste al ancho (Fit to Screen)
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    }

    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              Share.share(
                'Hola, adjunto el comprobante ${widget.title}: ${widget.url}',
                subject: widget.title,
              );
            },
            tooltip: 'Compartir enlace',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
