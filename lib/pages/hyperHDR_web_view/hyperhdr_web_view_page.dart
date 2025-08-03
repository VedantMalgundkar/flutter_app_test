import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../services/http_service_provider.dart';
import 'package:provider/provider.dart';

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  WebViewController? _controller;
  bool _hasError = false;
  bool _isDesktopMode = false;

  Future<void> _setupWebView(Uri uri) async {
    try {
      final controller = WebViewController();

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _hasError = false),
            onPageFinished: (_) => _injectViewport(controller),
            onWebResourceError: (_) => setState(() => _hasError = true),
          ),
        );

      if (controller.platform is AndroidWebViewController) {
        final android = controller.platform as AndroidWebViewController;
        await android.setMediaPlaybackRequiresUserGesture(false);
      }

      await controller.loadRequest(uri);

      setState(() => _controller = controller);
    } catch (e) {
      debugPrint("WebView setup error: $e");
      setState(() => _hasError = true);
    }
  }

  void _injectViewport(WebViewController controller) {
    final content = _isDesktopMode
        ? 'width=1024'
        : 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';

    controller.runJavaScript('''
      (() => {
        var meta = document.querySelector('meta[name="viewport"]');
        if (meta) {
          meta.setAttribute('content', '$content');
        } else {
          meta = document.createElement('meta');
          meta.name = "viewport";
          meta.content = "$content";
          document.head.appendChild(meta);
        }
      })();
    ''');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hyperUri = context.watch<HttpServiceProvider>().hyperUri;
    if (hyperUri != null && _controller == null) {
      _setupWebView(hyperUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hyperUri = context.watch<HttpServiceProvider>().hyperUri;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          "Configuration Panel",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Builder(
        builder: (context) {
          if (_hasError) {
            return _buildError();
          }

          if (_controller == null || hyperUri == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              WebViewWidget(controller: _controller!),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() => _isDesktopMode = !_isDesktopMode);
                    _injectViewport(_controller!);
                  },
                  tooltip: _isDesktopMode
                      ? 'Switch to Phone Mode'
                      : 'Switch to Desktop Mode',
                  child: Icon(
                    _isDesktopMode
                        ? Icons.phone_android
                        : Icons.desktop_windows,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Failed to load WebView'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final uri = context.read<HttpServiceProvider>().hyperUri;
              if (uri != null) _setupWebView(uri);
            },
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure:\n1. Server is running\n2. Correct IP address\n3. Same network',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
