import 'package:flutter/material.dart';
import '../../control_modal/control_modal_toggle.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';
import '../../pages/hyperhdr_discovery_page/hyperhdr_service_list.dart';
import '../../services/ble_service.dart';
import 'package:get_it/get_it.dart';
import '../wifi_page/wifi_page.dart';
import '../hyperHDR_web_view/hyperhdr_web_view_page.dart';
import 'led_control_dash_board.dart';

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
      drawer: Builder(
        builder: (context) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.65, // 50% width
          child: Drawer(
            child: ListView(
              children: [
                DrawerHeader(child: Text('Header')),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.grey[500]),
                  title: Text('Configuration', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WebViewContainer(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            color: Colors.black,
          ),
        ),
        title: const Text(
          "LED Control",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
          Positioned.fill(child: LightControlWidget()),
          
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
          // arrow down
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
