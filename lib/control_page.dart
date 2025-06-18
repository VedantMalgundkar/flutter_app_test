import 'package:flutter/material.dart';
import './control_widgets/hyperhdr_toggle.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned.fill(child: WebViewContainer()),
        Positioned(top: 0, left: 0, right: 0, child: HyperhdrToggle()),
      ],
    );
  }
}

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late final WebViewController _controller;
  bool _isWebViewInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Initialize platform for Android
      if (WebViewPlatform.instance is! AndroidWebViewPlatform) {
        WebViewPlatform.instance = AndroidWebViewPlatform();
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              debugPrint('Page started loading: $url');
              setState(() => _hasError = false);
            },
            onPageFinished: (url) {
              debugPrint('Page finished loading: $url');
              // Inject CSS to prevent zooming
              _controller.runJavaScript('''
                document.querySelector('meta[name="viewport"]')?.setAttribute(
                  'content', 
                  'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'
                );
              ''');
            },
            onWebResourceError: (error) {
              debugPrint('Web resource error: ${error.description}');
              setState(() => _hasError = true);
            },
          ),
        );

      // Configure Android-specific settings
      if (_controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        final androidController =
            _controller.platform as AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      // Load the URL after a slight delay to ensure WebView is ready
      await Future.delayed(const Duration(milliseconds: 100));
      await _controller.loadRequest(Uri.parse('http://192.168.0.111:8090/'));

      setState(() => _isWebViewInitialized = true);
    } catch (e) {
      debugPrint('WebView initialization error: $e');
      setState(() => _hasError = true);
    }
  }

  Future<void> _reloadWebView() async {
    setState(() {
      _isWebViewInitialized = false;
      _hasError = false;
    });
    await _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load WebView'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reloadWebView,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ensure: \n1. Server is running\n2. Correct IP address\n3. Same network',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (!_isWebViewInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _controller);
  }
}
