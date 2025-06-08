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
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final password = _passwordController.text;
                    Navigator.of(context).pop(); // Close dialog

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
