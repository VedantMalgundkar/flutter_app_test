import 'package:flutter/material.dart';
import '../../control_modal/control_modal_toggle.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';
import '../../pages/hyperhdr_discovery_page/hyperhdr_service_list.dart';
import '../../services/ble_service.dart';
import 'package:get_it/get_it.dart';
import '../wifi_page/wifi_page.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final HttpService _hyperhdr;
  final BleService bleService = GetIt.I<BleService>();
  String _ssid = "---";
  String? _mac;
  bool _isChangeDeviceDrawerOpen = false;
  bool _isControlModalOpen = false;

  @override
  void initState() {
    super.initState();
    // _hyperhdr = HttpService(baseUrl: widget.url.toString());
    _hyperhdr = context.read<HttpServiceProvider>().service;
    _getConnectedWifi();
    _getMacId();
  }

  Future<void> _getConnectedWifi() async {
    try {
      final result = await _hyperhdr.getConnectedWifi();
      final network = result?["network"];
      if (mounted) {
        setState(() {
          _ssid = network?["ssid"] ?? "---";
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch connected Wi-Fi: $e");
      setState(() => _ssid = "---");
    }
  }

  Future<void> _getMacId() async {
    try {
      final result = await _hyperhdr.getMac();
      final mac = result?["mac"];
      _mac = mac.toUpperCase();
    } catch (e) {
      debugPrint("Failed to fetch mac id: $e");
      _mac = "";
    }
  }

  Future<void> handleWifiIconClick() async {
    try {
      if (_mac == null || _mac!.isEmpty) {
        debugPrint("MAC address is null or empty.");
        return;
      }

      print("MAC addr is >>>> $_mac");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WifiPage(deviceId: _mac!, isFetchApi: true),
        ),
      );
    } catch (e) {
      debugPrint("Error navigating to WifiPage: $e");
    }
  }

  void closeControlDrawer() {
    setState(() {
      _isControlModalOpen = false;
    });
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
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isChangeDeviceDrawerOpen = !_isChangeDeviceDrawerOpen;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero, // Prevents default min size
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sync_alt, size: 10),
                    SizedBox(width: 4),
                    Text("Change Device", style: TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        handleWifiIconClick();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(Icons.wifi),
                    ),
                    const SizedBox(height: 2), // small manual spacing
                    SizedBox(
                      width: 60,
                      child: Text(
                        _ssid,
                        style: const TextStyle(fontSize: 8, height: 1),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewContainer()),
          // BACKDROP to dismiss drawer
          if (_isChangeDeviceDrawerOpen || _isControlModalOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isChangeDeviceDrawerOpen = false;
                    _isControlModalOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                ),
              ),
            ),

          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _isControlModalOpen = !_isControlModalOpen;
                    });
                    // handle button
                  },
                ),
              ],
            ),
          ),

          //hyperhdr service control
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _isControlModalOpen ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: _isControlModalOpen
                      ? ControlModalToggle(onClose: closeControlDrawer)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Change Device Drawer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _isChangeDeviceDrawerOpen
                  ? Offset.zero
                  : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 300,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: HyperhdrServiceList(
                    onSelect: (selectedDevice) {
                      final url = selectedDevice['url'] as Uri;
                      final hyperUrl = selectedDevice['hyperUrl'] as Uri;

                      print("url $url");
                      print("hyperUrl $hyperUrl");
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
