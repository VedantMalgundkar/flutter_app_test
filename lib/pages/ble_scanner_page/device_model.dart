import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class CustomBleDevice {
  final DiscoveredDevice device;
  final bool disabled;
  final bool isConnected;

  CustomBleDevice({
    required this.device,
    this.disabled = false,
    this.isConnected = false,
  });

  CustomBleDevice copyWith({bool? disabled, bool? isConnected}) {
    return CustomBleDevice(
      device: device,
      disabled: disabled ?? this.disabled,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}