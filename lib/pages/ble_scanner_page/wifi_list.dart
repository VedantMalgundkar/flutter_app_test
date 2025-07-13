import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_service.dart';
import '../../services/http_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';
import './wif_password_dialog.dart';

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
  String _mac = "";
  bool isLoading = false;
  final ValueNotifier<bool> iswriteLoading = ValueNotifier(false);
  bool isBleConnFailed = false;

  List<Map<String, dynamic>> connectedWifi = [];
  List<Map<String, dynamic>> savedWifi = [];
  List<Map<String, dynamic>> otherWifi = [];

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  late final Function(String, String) wifiActionThrottledHandler;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    wifiActionThrottledHandler = throttledWifiAction();
    // Future.delayed(Duration(seconds: 10), () {
    //   iswriteLoading.value = false;
    // });
  }

  Future<void> _initialize() async {
    if (widget.isFetchApi) {
      // Start async work without awaiting — allows UI to build first
      Future(() async {
        iswriteLoading.value = true;

        try {
          await bleService.connectToDevice(deviceId: widget.deviceId);
          if (mounted) {
            iswriteLoading.value = false;
            print("BLE Connected. >>>>");
          }
          await _getMacId();
        } catch (e) {
          print("BLE connection failed: $e");
          if (mounted) {
            iswriteLoading.value = false;
            isBleConnFailed = true;
          }
        }
      });
    } else {
      await _getMacId();
    }

    // This happens immediately after widget build
    if (widget.isFetchApi) {
      _hyperhdr = context.read<HttpServiceProvider>().service;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
    });
  }

  Future<void> _getMacId() async {
    try {
      final mac = await bleService.readMac();
      print("BLE MAC RESULT >>>>>>>> $mac");
      _mac = mac.toUpperCase();
      print("mac :>>> $_mac");
    } catch (e) {
      debugPrint("Failed to fetch mac id: $e");
      _mac = "";
    }
  }

  Future<void> handleWifiCredsWrite(String ssid, String password) async {
    if (isBleConnFailed) return;

    print("SSID: $ssid, Password: $password");

    try {
      if (password.trim().isEmpty) {
        throw ArgumentError("Password cannot be empty");
      }

      final statusJson = await bleService.sendCredentialsAndWaitForStatus(
        _mac,
        ssid,
        password,
      );

      final data = jsonDecode(statusJson);

      if (data['status'] != 'success') {
        throw Exception(data['error'] ?? 'Failed to connect');
      }

      await _loadWifiList();
      Navigator.of(context).pop();
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Invalid input")));
    } catch (e) {
      print("Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showPasswordDialog(String ssid) {
    showDialog(
      context: context,
      builder: (context) {
        return WifiPasswordDialog(
          ssid: ssid,
          loadingNotifier: iswriteLoading,
          onSubmit: handleWifiCredsWrite,
        );
      },
    );
  }

  Future<void> _loadWifiList() async {
    print("\n <<<<<<<<<<<<<<<<<< called _loadWifiList >>>>>>>>>>>>>>> \n");
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

  Future<void> handleWifiAction(ssid, action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String actionData;
      switch (action) {
        case 'connect':
          actionData = "add";
          break;
        case 'disconnect':
          actionData = "sub";
          break;
        case 'forget':
          actionData = "del";
          break;
        default:
          throw ArgumentError("Invalid action: $action");
      }

      final statusJson = await bleService.commonWifiActions(
        _mac,
        ssid,
        actionData,
      );

      final data = jsonDecode(statusJson);
      if (data['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${data['error'] ?? 'Unknown error'}")),
        );
        return;
      }
      await _loadWifiList();
    } catch (e) {
      print("Unexpected error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Function(String, String) throttledWifiAction() {
    bool inProgress = false;

    return (String ssid, String action) async {
      if (inProgress) return;
      inProgress = true;

      try {
        await handleWifiAction(ssid, action);
      } finally {
        inProgress = false;
      }
    };
  }

  @override
  void dispose() {
    if (widget.isFetchApi) {
      bleService.disconnect();
    }
    super.dispose();
  }

  Widget buildTopLinearLoader(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 4,
      color: Colors.transparent,
      child: LinearProgressIndicator(
        minHeight: 4,
        backgroundColor: primary.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          key: _refreshKey,
          onRefresh: _loadWifiList,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            children: [
              if (connectedWifi.isNotEmpty)
                ...connectedWifi.map((wifi) => _buildWifiTile(wifi)),

              if (savedWifi.isNotEmpty) ...[
                _buildSectionHeader(
                  "Saved Networks",
                  wantBorder: connectedWifi.isNotEmpty,
                ),
                ...savedWifi.map((wifi) => _buildWifiTile(wifi)),
              ],

              if (otherWifi.isNotEmpty) ...[
                _buildSectionHeader("Available Networks"),
                ...otherWifi.map((wifi) => _buildWifiTile(wifi)),
              ],
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: iswriteLoading,
          builder: (context, listenableLoading, _) {
            if (_isLoading || listenableLoading) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: buildTopLinearLoader(context),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool wantBorder = true}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: wantBorder
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 198, 198, 198),
                  width: 0.5,
                ),
              ),
            )
          : null,
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
    final isSaved = wifi["sav"] == 1;

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

            if (isSaved || isConnected)
              ValueListenableBuilder(
                valueListenable: iswriteLoading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return IconTheme(
                      data: IconThemeData(
                        color: Theme.of(context).disabledColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: const Icon(Icons.more_vert),
                      ),
                    );
                  }
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      wifiActionThrottledHandler(ssid, value);
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: isConnected ? 'disconnect' : 'connect',
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                      const PopupMenuItem(
                        value: 'forget',
                        child: Text('Forget'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  );
                },
              ),
          ],
        ),
      ),
      onTap: () {
        if (isConnected || ((!locked || isSaved) && iswriteLoading.value)) {
          return;
        }

        if (isSaved || !locked) {
          wifiActionThrottledHandler(ssid, "connect");
        } else {
          _showPasswordDialog(ssid);
        }
      },
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
