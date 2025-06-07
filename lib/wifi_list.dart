import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';

class WifiListPage extends StatefulWidget {
  final String deviceId;

  const WifiListPage({super.key, required this.deviceId});

  @override
  State<WifiListPage> createState() => _WifiListPageState();
}

class _WifiListPageState extends State<WifiListPage> {
  final BleService bleService = GetIt.I<BleService>();
  List<Map<String, dynamic>> wifiList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWifiList();
  }

  Future<void> _loadWifiList() async {
    setState(() {
      isLoading = true;
    });
    final result = await bleService.discoverAndReadWifi(widget.deviceId);
    setState(() {
      wifiList = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wi-Fi Networks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWifiList, // 🔁 Refresh Wi-Fi list
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: wifiList.length,
              itemBuilder: (context, index) {
                final wifi = wifiList[index];
                return ListTile(
                  title: Text(wifi["ssid"] ?? "Unknown SSID"),
                  subtitle: Text("Signal: ${wifi["signal"]}"),
                );
              },
            ),
    );
  }
}
