import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => startScan());
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
        .listen((device) {
      if (devices.indexWhere((d) => d.id == device.id) == -1) {
        setState(() {
          devices.add(device);
        });
      }
    }, onError: (err) {
      print("Scan failed: $err");
    });
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
          return ListTile(
            title: Text(d.name.isNotEmpty ? d.name : "(No name)"),
            subtitle: Text("ID: ${d.id}  RSSI: ${d.rssi}"),
          );
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
