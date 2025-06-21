import 'package:flutter/material.dart';
import '../services/http_service.dart';
import './version_tile.dart';

class VersionInfoPage extends StatefulWidget {
  final Uri url;
  const VersionInfoPage({super.key, required this.url});

  @override
  State<VersionInfoPage> createState() => _VersionInfoPageState();
}

class _VersionInfoPageState extends State<VersionInfoPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> versionList = [];
  late final HttpService _hyperhdr;

  @override
  void initState() {
    super.initState();
    _hyperhdr = HttpService(baseUrl: widget.url.toString());
    _loadVersionList();
  }

  Future<void> _loadVersionList() async {
    print("ran _loadVersionList");
    try {
      setState(() {
        isLoading = true;
      });
      final versions = await _hyperhdr.getAvlVersions();
      if (!mounted) return;
      setState(() {
        versionList = versions;
      });
    } catch (e) {
      print(e);
      setState(() {
        versionList = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Versions"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVersionList,
        child: ListView.builder(
          itemCount: versionList.length,
          itemBuilder: (context, index) {
            final version = versionList[index];
            return VersionTile(
              version: version,
              onInstallationComplete: _loadVersionList,
              url: widget.url,
            );
          },
        ),
      ),
    );
  }
}
