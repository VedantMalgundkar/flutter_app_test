import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';
import './wifi_list.dart';

class BleDeviceTile extends StatefulWidget {
  final DiscoveredDevice device;

  const BleDeviceTile({Key? key, required this.device}) : super(key: key);

  @override
  State<BleDeviceTile> createState() => _BleDeviceTileState();
}

class _BleDeviceTileState extends State<BleDeviceTile> {
  bool isLoading = false;
  bool isConnected = false;
  final BleService bleService = GetIt.I<BleService>();

  Future<void> _handleConnect() async {
    setState(() => isLoading = true);

    final success = await bleService.connectToDevice(widget.device);

    setState(() {
      isLoading = false;
      isConnected = success;
    });

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WifiListPage(deviceId: widget.device.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.device.name.isNotEmpty ? widget.device.name : "(No name)",
      ),
      subtitle: Text("ID: ${widget.device.id}  RSSI: ${widget.device.rssi}"),
      trailing: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isConnected
          ? const Text("Connected", style: TextStyle(color: Colors.green))
          : ElevatedButton(
              onPressed: _handleConnect,
              child: const Text("Connect"),
            ),
    );
  }
}
