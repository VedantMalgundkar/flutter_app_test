import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_service.dart';
import '../wifi_page/wifi_page.dart';

class BleDeviceTile extends StatefulWidget {
  final DiscoveredDevice device;
  final bool disabled;
  final void Function(String deviceId)? onLoading;
  final void Function()? onDisconnect;

  const BleDeviceTile({
    Key? key,
    required this.device,
    required this.disabled,
    this.onLoading,
    this.onDisconnect,
  }) : super(key: key);

  @override
  State<BleDeviceTile> createState() => _BleDeviceTileState();
}

class _BleDeviceTileState extends State<BleDeviceTile> {
  bool isLoading = false;
  final BleService bleService = GetIt.I<BleService>();
  bool isConnected = false;
  bool get isGloballyConnected =>
      widget.device.id == bleService.connectedDeviceId;

  Future<void> _handleRedirect() async {
    final ipaddr = await bleService.readIp(deviceId: widget.device.id);
    print("ip is >>>>>>> $ipaddr");

    final bool hasValidIp = ipaddr != null && ipaddr.trim().isNotEmpty;

    final nextPage = WifiPage(deviceId: widget.device.id, isFetchApi: false);

    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  // Future<void> _handleConnect() async {
  //   setState(() => isLoading = true);

  //   try {
  //     final success = await bleService.connectToDevice(device: widget.device);

  //     if (!success) {
  //       setState(() => isLoading = false);
  //       print("Failed to connect to device.");
  //       return;
  //     }

  //     setState(() {
  //       isConnected = true;
  //       isLoading = false;
  //     });

  //     await _handleRedirect();
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     print("Error during connection or IP read: $e");
  //   }
  // }
  Future<void> _handleConnect() async {
    setState(() => isLoading = true);

    try {
      if (isConnected || bleService.connectedDeviceId == widget.device.id) {
        await bleService.disconnect();

        if (widget.onDisconnect != null) {
          widget.onDisconnect!();
        }

        setState(() {
          isConnected = false;
          isLoading = false;
        });

        return;
      }

      if (widget.onLoading != null) {
        widget.onLoading!(widget.device.id);
      }

      print("connecting to  ${widget.device.id}");

      final success = await bleService.connectToDevice(device: widget.device);

      if (!success) {
        setState(() => isLoading = false);
        print("Failed to connect to device.");
        return;
      }

      setState(() {
        isConnected = true;
        isLoading = false;
      });
      // await _handleRedirect();
    } catch (e) {
      setState(() => isLoading = false);
      print("Error during connection or IP read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGloballyConnected ? Colors.green : Colors.transparent,
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
        trailing: ElevatedButton(
          onPressed: widget.disabled ? null : _handleConnect,
          child: SizedBox(
            width: 54,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      widget.disabled
                          ? "disabled"
                          : (isConnected || isGloballyConnected)
                          ? "Disconnect"
                          : "Connect",
                    ),
            ),
          ),
        ),

        // widget.disabled ? ElevatedButton(
        //       onPressed: ()=>{},
        //       child: const Text("disabled"),
        //     ):
        // isLoading
        //   ? const SizedBox(
        //       height: 20,
        //       width: 20,
        //       child: CircularProgressIndicator(strokeWidth: 2),
        //     )
        //   : isConnected || isGloballyConnected
        //   ? ElevatedButton(
        //       onPressed: _handleConnect,
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.green,
        //         foregroundColor: Colors.white,
        //         textStyle: const TextStyle(fontWeight: FontWeight.bold),
        //       ),
        //       child: const Text("Reconnect"),
        //     )
        //   : ElevatedButton(
        //       onPressed: _handleConnect,
        //       child: const Text("Connect"),
        //     ),
      ),
    );
  }
}
