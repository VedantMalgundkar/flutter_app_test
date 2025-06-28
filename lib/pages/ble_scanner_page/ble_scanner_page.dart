import 'package:flutter/material.dart';
import './ble_service_list.dart';

class BleScannerPage extends StatelessWidget {
  const BleScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Device to Network")),
      body: BleServiceList(),
    );
  }
}
