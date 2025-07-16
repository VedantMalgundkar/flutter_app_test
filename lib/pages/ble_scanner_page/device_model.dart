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

  CustomBleDevice copyWith({
    DiscoveredDevice? device,
    bool? isConnected,
    bool? disabled,
  }) {
    return CustomBleDevice(
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
      disabled: disabled ?? this.disabled,
    );
  }
}