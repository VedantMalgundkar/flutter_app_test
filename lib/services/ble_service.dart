import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleService {
  final FlutterReactiveBle _ble;
  BleService(this._ble);
  String? _connectedDeviceId;
  String? get connectedDeviceId => _connectedDeviceId;

  // UUIDs from your Python BLE server
  final Uuid wifiServiceUuid = Uuid.parse(
    "00000001-710e-4a5b-8d75-3e5b444bc3cf",
  );
  final Uuid scanCharUuid = Uuid.parse("00000003-710e-4a5b-8d75-3e5b444bc3cf");
  final Uuid statusCharUuid = Uuid.parse(
    "00000004-710e-4a5b-8d75-3e5b444bc3cf",
  );
  final Uuid ipCharUuid = Uuid.parse("00000005-710e-4a5b-8d75-3e5b444bc3cf");

  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  Future<bool> connectToDevice({
    DiscoveredDevice? device,
    String? deviceId,
  }) async {
    final completer = Completer<bool>();
    final String? id = device?.id ?? deviceId;

    if (id == null) {
      throw ArgumentError("Either 'device' or 'deviceId' must be provided.");
    }

    _connectionSub?.cancel();
    _connectionSub = _ble
        .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 10))
        .listen(
          (state) async {
            print("Connection State: ${state.connectionState}");

            if (state.connectionState == DeviceConnectionState.connected) {
              print("Connected to ${device?.name ?? 'device'}  $id");
              _connectedDeviceId = id;
              completer.complete(true);
            }

            if (state.connectionState == DeviceConnectionState.disconnected) {
              print("Disconnected from $id");
              if (!completer.isCompleted) {
                _connectedDeviceId = null;
                completer.complete(false);
              }
            }
          },
          onError: (e) {
            print("Connection error: $e");
            if (!completer.isCompleted) {
              _connectedDeviceId = null;
              completer.complete(false);
            }
          },
        );

    return completer.future;
  }

  Future<void> disconnect() async {
    print("ran ble disconnected method.");
    await _connectionSub?.cancel();
    _connectedDeviceId = null;
    print("Disconnected successfully.");
  }

  Future<List<Map<String, dynamic>>> discoverAndReadWifi(
    String deviceId,
  ) async {
    try {
      print("device ID >>>>>>>>>>>> $deviceId");
      await _ble.discoverAllServices(deviceId); // Triggers discovery
      final services = await _ble.getDiscoveredServices(deviceId);
      // final List<DiscoveredService> services = await _ble.getDiscoveredServices(deviceId);

      for (var service in services) {
        if (service.id == wifiServiceUuid) {
          for (var char in service.characteristics) {
            if (char.id == scanCharUuid) {
              return await _readWifiList(deviceId, char.id);
            }
          }
        }
      }
    } catch (e) {
      print("Service discovery failed: $e");
    }
    return [];
  }

  String fixPartialJson(String raw) {
    if (raw.startsWith('[')) raw = raw.substring(1);
    if (raw.endsWith(']')) raw = raw.substring(0, raw.length - 1);

    List<String> parts = raw.split('},');
    parts.removeLast();

    // Rebuild each part to make valid JSON objects again
    List<String> fixedParts = parts.map((p) {
      p = p.trim();
      // If it already ends with '}', don't add it
      if (!p.endsWith('}')) {
        p += '}';
      }
      return p;
    }).toList();

    // Join the objects into a JSON array
    String fixed = '[${fixedParts.join(',')}]';

    return fixed;
  }

  Future<List<Map<String, dynamic>>> _readWifiList(
    String deviceId,
    Uuid charUuid,
  ) async {
    try {
      final result = await _ble.readCharacteristic(
        QualifiedCharacteristic(
          serviceId: wifiServiceUuid,
          characteristicId: charUuid,
          deviceId: deviceId,
        ),
      );

      final jsonStr = utf8.decode(result);
      final fixedJsonStr = fixPartialJson(jsonStr);

      final list = (json.decode(fixPartialJson(fixedJsonStr)) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return list;
    } catch (e) {
      print("Error reading Wi-Fi list: $e");
      return [];
    }
  }

  Future<bool> writeCredentials(
    String deviceId,
    String ssid,
    String password,
  ) async {
    final data = utf8.encode(json.encode({"ssid": ssid, "password": password}));
    final characteristic = QualifiedCharacteristic(
      serviceId: wifiServiceUuid,
      characteristicId: scanCharUuid,
      deviceId: deviceId,
    );

    try {
      await _ble.writeCharacteristicWithResponse(characteristic, value: data);
      print("Wi-Fi credentials sent");
      return true;
    } catch (e) {
      print("Write failed: $e");
      return false;
    }
  }

  Future<String> readStatus(String deviceId) async {
    try {
      final char = QualifiedCharacteristic(
        serviceId: wifiServiceUuid,
        characteristicId: statusCharUuid,
        deviceId: deviceId,
      );

      final result = await _ble.readCharacteristic(char);
      return utf8.decode(result);
    } catch (e) {
      print("Failed to read status: $e");
      return "Error";
    }
  }

  Future<String> readIp({required String deviceId}) async {
    final char = QualifiedCharacteristic(
      serviceId: wifiServiceUuid,
      characteristicId: ipCharUuid,
      deviceId: deviceId,
    );

    final result = await _ble.readCharacteristic(char);
    return utf8.decode(result);
  }
}
