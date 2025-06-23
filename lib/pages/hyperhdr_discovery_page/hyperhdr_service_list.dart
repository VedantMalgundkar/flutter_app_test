import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../services/hyperhdr_discovery_service.dart';
import 'package:provider/provider.dart';
import '../../services/http_service_provider.dart';

class HyperhdrServiceList extends StatefulWidget {
  final void Function(Map<String, dynamic> selected)? onSelect;

  const HyperhdrServiceList({super.key, this.onSelect});

  @override
  State<HyperhdrServiceList> createState() => _HyperhdrServiceListState();
}

class _HyperhdrServiceListState extends State<HyperhdrServiceList> {
  final discoveryService = GetIt.instance<HyperhdrDiscoveryService>();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>>? servers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
      _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final result = await discoveryService.discover();
      if (!mounted) return;
      setState(() {
        servers = result;
      });
    } catch (e) {
      debugPrint("❌ Discovery failed: $e");
      if (!mounted) return;
      setState(() {
        servers = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refresh,
      child: servers == null
          ? ListView() // Required so RefreshIndicator can trigger
          : servers!.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No servers found")),
                ),
              ],
            )
          : ListView.builder(
              itemCount: servers!.length,
              itemBuilder: (context, index) {
                final device = servers![index];
                final label = device["label"];
                final globalUri = context.read<HttpServiceProvider>().baseUrl;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    // horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfffffbff),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    title: Text(label),
                    trailing: globalUri == device["url"]
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: const Size(100, 30),
                            ),
                            child: const Text("Connect"),
                            onPressed: () => widget.onSelect?.call(device),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
