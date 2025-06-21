import 'package:flutter/material.dart';
import '../ble_scanner_page/ble_scanner_page.dart';
import './hyperhdr_service_list.dart';
import '../control_page/control_page.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';

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
        onSelect: (selectedDevice) {
          final url = selectedDevice['url'] as Uri;
          final hyperUrl = selectedDevice['hyperUrl'] as Uri;

          context.read<HttpServiceProvider>().updateBaseUrl(url);
          context.read<HttpServiceProvider>().updateHyperUri(hyperUrl);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ControlPage()),
          );
        },
      ),
    );
  }
}
