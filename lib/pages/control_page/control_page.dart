import 'package:flutter/material.dart';
import '../../control_modal/control_modal_toggle.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final HttpService _hyperhdr;
  String _ssid = "---"; // default fallback
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _hyperhdr = HttpService(baseUrl: widget.url.toString());
    _hyperhdr = context.read<HttpServiceProvider>().service;
    _getConnectedWifi();
  }

  Future<void> _getConnectedWifi() async {
    setState(() => isLoading = true);

    try {
      final result = await _hyperhdr.getConnectedWifi();
      final network = result?["network"];
      if (mounted) {
        setState(() {
          _ssid = network?["ssid"] ?? "---";
        });
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch connected Wi-Fi: $e");
      setState(() => _ssid = "---");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HyperHDR Control",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600, // Optional
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi),
                const SizedBox(height: 1),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      _ssid,
                      style: const TextStyle(fontSize: 8),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewContainer()),
          Positioned(top: 0, left: 0, right: 0, child: ControlModalToggle()),
        ],
      ),
    );
  }
}

// class WebViewContainer extends StatefulWidget {
//   const WebViewContainer({super.key});

//   @override
//   State<WebViewContainer> createState() => _WebViewContainerState();
// }

// class _WebViewContainerState extends State<WebViewContainer> {
//   late final WebViewController _controller;
//   bool _isWebViewInitialized = false;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }

//   Future<void> _initializeWebView() async {
//     try {
//       // Initialize platform for Android
//       if (WebViewPlatform.instance is! AndroidWebViewPlatform) {
//         WebViewPlatform.instance = AndroidWebViewPlatform();
//       }

//       _controller = WebViewController()
//         ..setJavaScriptMode(JavaScriptMode.unrestricted)
//         ..setBackgroundColor(Colors.transparent)
//         ..setNavigationDelegate(
//           NavigationDelegate(
//             onPageStarted: (url) {
//               debugPrint('Page started loading: $url');
//               setState(() => _hasError = false);
//             },
//             onPageFinished: (url) {
//               debugPrint('Page finished loading: $url');
//               // Inject CSS to prevent zooming
//               _controller.runJavaScript('''
//                 document.querySelector('meta[name="viewport"]')?.setAttribute(
//                   'content',
//                   'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'
//                 );
//               ''');
//             },
//             onWebResourceError: (error) {
//               debugPrint('Web resource error: ${error.description}');
//               setState(() => _hasError = true);
//             },
//           ),
//         );

//       // Configure Android-specific settings
//       if (_controller.platform is AndroidWebViewController) {
//         AndroidWebViewController.enableDebugging(true);
//         final androidController =
//             _controller.platform as AndroidWebViewController;
//         await androidController.setMediaPlaybackRequiresUserGesture(false);
//       }

//       // Load the URL after a slight delay to ensure WebView is ready
//       await Future.delayed(const Duration(milliseconds: 100));
//       await _controller.loadRequest(Uri.parse('http://192.168.0.111:8090/'));

//       setState(() => _isWebViewInitialized = true);
//     } catch (e) {
//       debugPrint('WebView initialization error: $e');
//       setState(() => _hasError = true);
//     }
//   }

//   Future<void> _reloadWebView() async {
//     setState(() {
//       _isWebViewInitialized = false;
//       _hasError = false;
//     });
//     await _initializeWebView();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_hasError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Failed to load WebView'),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _reloadWebView,
//               child: const Text('Retry'),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Ensure: \n1. Server is running\n2. Correct IP address\n3. Same network',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     if (!_isWebViewInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return WebViewWidget(controller: _controller);
//   }
// }

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
      late final WebViewController controller;

      controller = WebViewController()
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
        ? 'width=1024' // Desktop-like width
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
    if (hyperUri != null) {
      _setupWebView(hyperUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hyperUri = context.watch<HttpServiceProvider>().hyperUri;

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
            child: Icon(
              _isDesktopMode ? Icons.phone_android : Icons.desktop_windows,
            ),
            tooltip: _isDesktopMode
                ? 'Switch to Phone Mode'
                : 'Switch to Desktop Mode',
          ),
        ),
      ],
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
