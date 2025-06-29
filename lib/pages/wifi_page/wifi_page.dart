import 'package:flutter/material.dart';
import '../ble_scanner_page/wifi_list.dart';

class WifiPage extends StatelessWidget {
  final String deviceId;
  final bool isFetchApi;

  const WifiPage({super.key, required this.deviceId, required this.isFetchApi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby WiFi")),
      body: WifiListWidget(deviceId: deviceId, isFetchApi: isFetchApi),
    );
  }
}
