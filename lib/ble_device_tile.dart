import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';
import './wifi_list.dart';
import './hyperhdr_control.dart';

class BleDeviceTile extends StatefulWidget {
  final DiscoveredDevice device;

  const BleDeviceTile({Key? key, required this.device}) : super(key: key);

  @override
  State<BleDeviceTile> createState() => _BleDeviceTileState();
}

class _BleDeviceTileState extends State<BleDeviceTile> {
  bool isLoading = false;
  final BleService bleService = GetIt.I<BleService>();
  bool isConnected = false;

  Future<void> _handleRedirect() async {
    final ipaddr = await bleService.readIp();
    print("ip is >>>>>>> $ipaddr");

    final bool hasValidIp = ipaddr != null && ipaddr.trim().isNotEmpty;

    final nextPage = hasValidIp
        ? HyperHdrController()
        : WifiListWidget(deviceId: widget.device.id);

    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  Future<void> _handleConnect() async {
    setState(() => isLoading = true);

    try {
      final success = await bleService.connectToDevice(widget.device);

      if (!success) {
        setState(() => isLoading = false);
        print("Failed to connect to device.");
        return;
      }

      setState(() {
        isConnected = true;
        isLoading = false;
      });

      await _handleRedirect();
    } catch (e) {
      setState(() => isLoading = false);
      print("Error during connection or IP read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.device.id == bleService.connectedDeviceId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          widget.device.name.isNotEmpty ? widget.device.name : "(No name)",
        ),
        subtitle: Text("ID: ${widget.device.id}  RSSI: ${widget.device.rssi}"),
        onTap: () async {
          await _handleRedirect();
        },
        trailing: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isConnected || isSelected
            ? ElevatedButton(
                onPressed: _handleConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text("Reconnect"),
              )
            : ElevatedButton(
                onPressed: _handleConnect,
                child: const Text("Connect"),
              ),
      ),
    );
  }
}
