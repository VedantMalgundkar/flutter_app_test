import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';
import 'package:http/http.dart' as http;

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final BleService bleService = GetIt.I<BleService>();
  String? base_url;

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await bleService.readIp();
    if (ip != null && ip.trim().isNotEmpty) {
      print(ip);
      final baseUrl = "http://$ip:5000";
      final statusRoute = "/status-hyperhdr";
      final fullUrl = Uri.parse("$baseUrl$statusRoute");

      try {
        final response = await http.get(fullUrl);

        if (response.statusCode == 200) {
          print("Success: ${response.body}");
        } else {
          print("Failed: ${response.statusCode}");
        }

        setState(() {
          base_url = baseUrl;
        });
      } catch (e) {
        print("Error: $e");
      }
    }

    setState(() {
      base_url = ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        base_url != null ? "IP: $base_url" : "Loading IP...",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
