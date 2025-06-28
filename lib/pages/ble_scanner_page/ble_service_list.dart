import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/ble_scanner_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import './ble_device_tile.dart';

class BleServiceList extends StatefulWidget {
  final void Function(Map<String, dynamic> selected)? onSelect;

  const BleServiceList({super.key, this.onSelect});

  @override
  State<BleServiceList> createState() => _BleServiceListState();
}

class _BleServiceListState extends State<BleServiceList> {
  final BleScannerService scannerService = GetIt.I<BleScannerService>();
  final FlutterReactiveBle reactiveBle = GetIt.I<FlutterReactiveBle>();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<DiscoveredDevice>? devices;
  StreamSubscription<BleStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
      _startScan();
    });
    _requestPermissionsAndStart();
  }

  Future<void> _requestPermissionsAndStart() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _statusSub = reactiveBle.statusStream.listen((status) async {
      if (status == BleStatus.ready) {
        await _startScan();
      } else if (status == BleStatus.poweredOff) {
        _showBluetoothOffDialog();
      }
    });
  }

  Future<void> _startScan() async {
    final completer = Completer<void>();

    scannerService
        .scanDevicesStream(duration: const Duration(seconds: 8))
        .listen(
          (deviceList) {
            setState(() {
              devices = deviceList;
            });
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (err) {
            print("Scan error: $err");
            if (!completer.isCompleted) completer.complete();
          },
        );
    return completer.future;
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bluetooth is Off"),
        content: const Text("Please enable Bluetooth to scan for devices."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    scannerService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _startScan,
      child: devices == null
          ? ListView()
          : devices!.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No Devices found")),
                ),
              ],
            )
          : ListView.builder(
              itemCount: devices?.length,
              itemBuilder: (context, index) {
                final d = devices?[index];
                if (d == null) return ListView();
                return BleDeviceTile(device: d);
              },
            ),
    );
  }
}
