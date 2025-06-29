import 'package:get_it/get_it.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_service.dart';
import 'hyperhdr_discovery_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<FlutterReactiveBle>(() => FlutterReactiveBle());

  getIt.registerLazySingleton<BleService>(
    () => BleService(getIt<FlutterReactiveBle>()),
  );

  getIt.registerLazySingleton<HyperhdrDiscoveryService>(
    () => HyperhdrDiscoveryService(),
  );
}
