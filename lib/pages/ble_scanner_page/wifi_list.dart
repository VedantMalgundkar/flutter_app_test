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
    }
    setState(() {
      wifiList = result;
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
      child: ListView.builder(
        itemCount: wifiList.length,
        itemBuilder: (context, index) {
          final wifi = wifiList[index];
          return ListTile(
            title: Text(wifi["s"] ?? "Unknown SSID"),
            subtitle: Text("Signal: ${wifi["sr"]}"),
            onTap: () {
              _showPasswordDialog(wifi["s"]);
            },
          );
        },
      ),
    );
  }
}
