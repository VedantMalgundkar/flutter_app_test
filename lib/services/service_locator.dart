import 'package:get_it/get_it.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_service.dart';
import 'hyperhdr_service.dart'; // <-- Import your new service

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<FlutterReactiveBle>(() => FlutterReactiveBle());

  getIt.registerLazySingleton<BleService>(
    () => BleService(getIt<FlutterReactiveBle>()),
  );

  getIt.registerLazySingleton<HyperhdrService>(
    () => HyperhdrService(
      baseUrl: "http://192.168.0.111:5000",
    ), // <-- Set base URL
  );
}
