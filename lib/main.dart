import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/ble_service.dart';
import 'ble_device_tile.dart';

void main() {
  runApp(const MyApp());
}

final flutterReactiveBle = FlutterReactiveBle();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BleScannerPage(),
    );
  }
}

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});
  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  List<DiscoveredDevice> devices = [];
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  final bleService = BleService(flutterReactiveBle);

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      flutterReactiveBle.statusStream.listen((status) {
        if (status == BleStatus.ready) {
          startScan();
        } else if (status == BleStatus.poweredOff) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Bluetooth is off"),
              content: const Text(
                "Please turn on Bluetooth to scan for devices.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      });
    });
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void startScan() {
    scanSubscription = flutterReactiveBle
        .scanForDevices(withServices: [])
        .listen(
          (device) {
            if (devices.indexWhere((d) => d.id == device.id) == -1) {
              setState(() {
                devices.add(device);
              });
            }
          },
          onError: (err) {
            print("Scan failed: $err");
          },
        );
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby BLE Devices")),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final d = devices[index];
          return BleDeviceTile(device: d, onConnect: () => _connectToDevice(d));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() => devices.clear());
          scanSubscription?.cancel();
          startScan();
        },
      ),
    );
  }
}
