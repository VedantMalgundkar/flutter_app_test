import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_service.dart';
import '../wifi_page/wifi_page.dart';

class BleDeviceTile extends StatefulWidget {
  final DiscoveredDevice device;
  final bool disabled;
  final void Function(String deviceId) onLoading;
  final void Function() onDisconnect;
  final void Function(String deviceId) onConnect;

  const BleDeviceTile({
    Key? key,
    required this.device,
    required this.disabled,
    required this.onLoading,
    required this.onDisconnect,
    required this.onConnect,
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
        widget.onDisconnect();

        setState(() {
          isConnected = false;
          isLoading = false;
        });

        return;
      }

      widget.onLoading(widget.device.id);

      print("connecting to  ${widget.device.id}");

      final success = await bleService.connectToDevice(device: widget.device);

      if (!success) {
        setState(() => isLoading = false);
        throw Exception("Failed to connect to device.");
      }

      setState(() {
        isConnected = true;
        isLoading = false;
      });

      widget.onConnect(widget.device.id);
      // await _handleRedirect();
    } catch (e) {
      final errorMessage = (e is Exception)
          ? e.toString().replaceFirst('Exception: ', '')
          : "Unknown error";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      setState(() {
        isConnected = false;
        isLoading = false;
      });
      widget.onDisconnect();
      print("Ble connectiion or disconnection Failed: $e");
    }
  }

  int normalizeRssi(int rssi) {
    const int min = -100;
    const int max = -30;

    if (rssi <= min) return 0;
    if (rssi >= max) return 100;

    return ((rssi - min) * 100 / (max - min)).round();
  }

  @override
  Widget build(BuildContext context) {
    final isAnyConnceted = (isConnected || isGloballyConnected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGloballyConnected
              ? Colors.green.shade200
              : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          widget.device.name.isNotEmpty ? "${widget.device.name}" : "(No name)",
          style: TextStyle(fontSize: 15.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "${widget.device.id}",
              style: TextStyle(fontSize: 12),
            ), // Spacing between icon and text
            const SizedBox(width: 8),
            const Icon(Icons.circle, size: 5),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(Icons.bluetooth_audio, size: 12),
                Text(
                  "${normalizeRssi(widget.device.rssi)}",
                  style: TextStyle(fontSize: 12),
                ), // Spacing between icon and text
              ],
            ),
          ],
        ),
        onTap: () async {
          await _handleRedirect();
        },
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isAnyConnceted
                ? Colors.red.shade100
                : Theme.of(context).colorScheme.primary,
            foregroundColor: isAnyConnceted
                ? Colors.red.shade700
                : Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minimumSize: const Size(100, 30),
          ),
          onPressed: widget.disabled ? null : _handleConnect,
          child: isLoading
              ? SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(isAnyConnceted ? "Disconnect" : "Connect"),
        ),

        // ElevatedButton(
        //   onPressed: widget.disabled ? null : _handleConnect,
        //   child: SizedBox(
        //     width: 54,
        //     child: Center(
        //       child: isLoading
        //           ? SizedBox(
        //               width: 15,
        //               height: 15,
        //               child: CircularProgressIndicator(
        //                 strokeWidth: 2.5,
        //                 valueColor: AlwaysStoppedAnimation<Color>(
        //                   Theme.of(context).colorScheme.primary,
        //                 ),
        //               ),
        //             )
        //           : Text(
        //               widget.disabled
        //                   ? "disabled"
        //                   : (isConnected || isGloballyConnected)
        //                   ? "Disconnect"
        //                   : "Connect",
        //             ),
        //     ),
        //   ),
        // ),

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
