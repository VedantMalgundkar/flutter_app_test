import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleScannerService {
  final FlutterReactiveBle _ble;
  StreamSubscription<DiscoveredDevice>? _scanSub;

  BleScannerService(this._ble);

  Stream<List<DiscoveredDevice>> scanDevicesStream({
    Duration duration = const Duration(seconds: 5),
  }) {
    final controller = StreamController<List<DiscoveredDevice>>();
    final List<DiscoveredDevice> scannedDevices = [];

    _scanSub = _ble.scanForDevices(withServices: []).listen((device) {
      if (scannedDevices.indexWhere((d) => d.id == device.id) == -1) {
        scannedDevices.add(device);
        controller.add(List.from(scannedDevices)); // emit copy
      }
    }, onError: (e) => controller.addError(e));

    Future.delayed(duration, () async {
      await _scanSub?.cancel();
      await controller.close();
    });

    return controller.stream;
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
  }
}
