import 'package:flutter/material.dart';
import 'services/service_locator.dart';
import 'package:provider/provider.dart';
import './services/http_service_provider.dart';
import './pages/hyperhdr_discovery_page/hyperhdr_discovery_page.dart';

void main() {
  setupLocator();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HttpServiceProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Devices',
      theme: ThemeData.from(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: const HyperhdrDiscoveryPage(),
    );
  }
}
