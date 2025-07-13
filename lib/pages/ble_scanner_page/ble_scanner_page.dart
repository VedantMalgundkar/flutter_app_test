import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import './ble_device_tile.dart';
// import '../../services/service_locator.dart';
import '../../services/ble_service.dart';
import 'package:get_it/get_it.dart';

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});
  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  List<DiscoveredDevice> devices = [];
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  // final bleService = BleService(flutterReactiveBle);
  final BleService bleService = GetIt.I<BleService>();
  late final Future<void> Function() startScanThrottled;
  bool isScanning = false;
  bool _throttleLock = false;
  Timer? _scanTimeoutTimer;

  @override
  void initState() {
    super.initState();
    startScanThrottled = throttledStartScan();

    requestPermissions().then((_) {
      flutterReactiveBle.statusStream.listen((status) {
        if (status == BleStatus.ready) {
          startScanThrottled();
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

  void stopScan({bool shouldSetState = true}) {
    scanSubscription?.cancel();
    scanSubscription = null;

    if (shouldSetState && mounted) {
      setState(() => isScanning = false);
    }

    _throttleLock = false;
  }

  Future<void> startScan() async {
    final targetServiceUuid = Uuid.parse(
      "00000001-710e-4a5b-8d75-3e5b444bc3cf",
    );

    // .scanForDevices(
    //   withServices: [targetServiceUuid],
    //   scanMode: ScanMode.lowLatency, // ensures fastest scanning
    // )
    setState(() => devices.clear());
    scanSubscription?.cancel();

    scanSubscription = flutterReactiveBle
        .scanForDevices(
          withServices: [],
          scanMode: ScanMode.lowLatency, // ensures fastest scanning
        )
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err.message ?? "Scanning Failed")),
            );
            stopScan();
          },
        );

    _scanTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) stopScan();
    });
  }

  Future<void> Function() throttledStartScan() {
    return () async {
      if (_throttleLock) return;
      _throttleLock = true;

      setState(() => isScanning = true);
      await startScan();
    };
  }

  @override
  void dispose() {
    stopScan(shouldSetState: false);
    _scanTimeoutTimer?.cancel();
    bleService.disconnect();
    super.dispose();
  }

  Widget buildTopLinearLoader(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 4,
      color: Colors.transparent,
      child: LinearProgressIndicator(
        minHeight: 4,
        backgroundColor: primary.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Device to Network")),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final d = devices[index];
              return BleDeviceTile(device: d);
            },
          ),
          if (isScanning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: buildTopLinearLoader(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          startScanThrottled();
        },
      ),
    );
  }
}
