import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../services/hyperhdr_discovery_service.dart';

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
      setState(() {
        servers = result;
      });
    } catch (e) {
      debugPrint("❌ Discovery failed: $e");
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
                return ListTile(
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onSelect?.call(device),
                );
              },
            ),
    );
  }
}
