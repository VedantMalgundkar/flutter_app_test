import 'package:flutter/material.dart';
import './wifi_list.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';
import './control_page.dart';

class HyperHdrController extends StatefulWidget {
  const HyperHdrController({super.key});

  @override
  State<HyperHdrController> createState() => _HyperHdrControllerState();
}

class _HyperHdrControllerState extends State<HyperHdrController> {
  int selectedPage = 0;
  final BleService bleService = GetIt.I<BleService>();
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    final deviceId = bleService.connectedDeviceId;
    pages = [
      ControlPage(),
      // if (deviceId != null)
      //   WifiListWidget(deviceId: deviceId)
      // else
      //   const Center(child: Text("No device connected")),
      Center(child: Text("Setting Page", style: const TextStyle(fontSize: 24))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HyperHdr Controller")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Navigation",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                setState(() {
                  selectedPage = 0;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                setState(() {
                  selectedPage = 1;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: pages[selectedPage],
    );
  }
}
