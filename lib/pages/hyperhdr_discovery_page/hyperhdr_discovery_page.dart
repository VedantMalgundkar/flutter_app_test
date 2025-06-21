import 'package:flutter/material.dart';
import '../ble_scanner_page/ble_scanner_page.dart';
import './hyperhdr_service_list.dart';
import '../control_page/control_page.dart';

class HyperhdrDiscoveryPage extends StatelessWidget {
  const HyperhdrDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Devices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Scan BLE Devices",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BleScannerPage()),
              );
            },
          ),
        ],
      ),
      body: HyperhdrServiceList(
        onSelect: (selected) {
          final url = selected['url'] as Uri;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ControlPage(url: url)),
          );
        },
      ),
    );
  }
}
