import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_service.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';

class WifiListWidget extends StatefulWidget {
  final String deviceId;
  final bool isFetchApi;

  const WifiListWidget({
    super.key,
    required this.deviceId,
    required this.isFetchApi,
  });

  @override
  State<WifiListWidget> createState() => _WifiListWidgetState();
}

class _WifiListWidgetState extends State<WifiListWidget> {
  late final HttpService? _hyperhdr;
  final BleService bleService = GetIt.I<BleService>();
  List<Map<String, dynamic>> wifiList = [];
  bool isLoading = false;
  bool iswriteLoading = false;
  bool isBleConnFailed = false;

  List<Map<String, dynamic>> connectedWifi = [];
  List<Map<String, dynamic>> savedWifi = [];
  List<Map<String, dynamic>> otherWifi = [];

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    debugPrint("initState of WifiListWidget");

    if (widget.isFetchApi) {
      setState(() {
        iswriteLoading = true;
      });

      bleService
          .connectToDevice(deviceId: widget.deviceId)
          .then((success) {
            if (mounted) {
              setState(() {
                iswriteLoading = false;
                print("ble Connected. >>>>");
              });
            }
          })
          .catchError((e) {
            print("BLE connection failed: $e");
            if (mounted) {
              setState(() {
                iswriteLoading = false;
                isBleConnFailed = true;
              });
            }
          });
    }

    if (widget.isFetchApi) {
      _hyperhdr = context.read<HttpServiceProvider>().service;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
    });
  }

  void _showPasswordDialog(String ssid) {
    final TextEditingController _passwordController = TextEditingController();
    bool _obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Connect to $ssid"),
              content: TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final password = _passwordController.text;
                    Navigator.of(context).pop();
                    print("SSID: $ssid, Password: $password");
                    // TODO: Use password + ssid
                  },
                  child: const Text("Connect"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadWifiList() async {
    setState(() {
      isLoading = true;
    });
    final result;
    if (widget.isFetchApi) {
      print("calling API >>>>>>");
      final res = await _hyperhdr!.scanNearbyNetworks();
      result = (res?["networks"] as List).cast<Map<String, dynamic>>();
    } else {
      print("calling BLE Service >>>>>>");
      result = await bleService.discoverAndReadWifi(widget.deviceId);
      // result = [
      //   {"s": "TP-Link_8CCC", "sr": 77, "lck": 1, "u": 1, "sav": 1},
      //   {"s": "Airtel_tush_5151", "sr": 97, "lck": 1, "u": 0, "sav": 0},
      //   {"s": "Airtel_ruke_7618", "sr": 65, "lck": 1, "u": 0, "sav": 1},
      //   {"s": "TP-Link_8CCC_EXT", "sr": 64, "lck": 1, "u": 0, "sav": 0},
      //   {"s": "Airtel_tush_5151", "sr": 62, "lck": 1, "u": 0, "sav": 1},
      //   {"s": "Borana5g", "sr": 39, "lck": 1, "u": 0, "sav": 0},
      //   {"s": "ZTE_2.4G_R653FD", "sr": 35, "lck": 1, "u": 0, "sav": 0},
      // ];
    }
    setState(() {
      connectedWifi = result.where((e) => e["u"] == 1).toList();
      savedWifi = result.where((e) => e["sav"] == 1 && e["u"] != 1).toList();
      otherWifi = result.where((e) => e["sav"] == 0 && e["u"] != 1).toList();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    if (widget.isFetchApi) {
      bleService.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _loadWifiList,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        children: [
          if (connectedWifi.isNotEmpty)
            ...connectedWifi.map((wifi) => _buildWifiTile(wifi)),

          if (savedWifi.isNotEmpty) ...[
            _buildSectionHeader("Saved Networks"),
            ...savedWifi.map((wifi) => _buildWifiTile(wifi)),
          ],

          if (otherWifi.isNotEmpty) ...[
            _buildSectionHeader("Available Networks"),
            ...otherWifi.map((wifi) => _buildWifiTile(wifi)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color.fromARGB(255, 198, 198, 198),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 15.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildWifiTile(Map<String, dynamic> wifi) {
    final ssid = wifi["s"] ?? "Unknown SSID";
    final signal = wifi["sr"] ?? 0;
    final locked = wifi["lck"] == 1;
    final isConnected = wifi["u"] == 1;

    return ListTile(
      title: Padding(
        padding: isConnected
            ? const EdgeInsets.symmetric(vertical: 8.0)
            : EdgeInsets.zero,
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _buildSignalIcon(signal),
                if (locked)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.lock, size: 10, color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ssid,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (isConnected)
                    Text(
                      "Connected",
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () => _showPasswordDialog(ssid),
    );
  }

  Widget _buildSignalIcon(int strength) {
    IconData icon;

    if (strength >= 75) {
      icon = Icons.wifi_rounded;
    } else if (strength >= 50) {
      icon = Icons.wifi_2_bar_rounded;
    } else if (strength >= 25) {
      icon = Icons.wifi_1_bar_rounded;
    } else {
      icon = Icons.wifi_off_rounded;
    }

    return Icon(icon);
  }
}
