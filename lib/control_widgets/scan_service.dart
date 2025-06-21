import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/hyperhdr_discovery_service.dart';

class ScanServicePage extends StatefulWidget {
  const ScanServicePage({super.key});

  @override
  State<ScanServicePage> createState() => _ScanServicePageState();
}

class _ScanServicePageState extends State<ScanServicePage> {
  bool isLoading = false;
  List<Uri> servers = [];
  final discoveryService = GetIt.instance<HyperhdrDiscoveryService>();

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    setState(() => isLoading = true);
    try {
      final result = await discoveryService.discover();
      setState(() {
        servers = result;
      });
    } catch (e) {
      debugPrint("❌ Error discovering services: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to discover services")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Service"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : servers.isEmpty
          ? const Center(child: Text("No servers found"))
          : ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final uri = servers[index];
                return ListTile(
                  title: Text(uri.toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Use or inject selected server
                    debugPrint("Selected: $uri");
                    Navigator.pop(context, uri);
                  },
                );
              },
            ),
    );
  }
}
