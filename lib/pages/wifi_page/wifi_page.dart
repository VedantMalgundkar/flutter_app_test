import 'package:flutter/material.dart';
import '../../wifi_list.dart';

class WifiPage extends StatelessWidget {
  final String deviceId;

  const WifiPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby WiFi")),
      body: WifiListWidget(deviceId: deviceId),
    );
  }
}
