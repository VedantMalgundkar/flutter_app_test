import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_service.dart';

class WifiListWidget extends StatefulWidget {
  final String deviceId;

  const WifiListWidget({super.key, required this.deviceId});

  @override
  State<WifiListWidget> createState() => _WifiListWidgetState();
}

class _WifiListWidgetState extends State<WifiListWidget> {
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
    return RefreshIndicator(
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
