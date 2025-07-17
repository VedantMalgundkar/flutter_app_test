import 'package:flutter/material.dart';
import '../services/http_service.dart';
import './version_tile.dart';
import 'package:provider/provider.dart';
import '../services/http_service_provider.dart';

class VersionInfoPage extends StatefulWidget {
  const VersionInfoPage({super.key});

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
    _hyperhdr = context.read<HttpServiceProvider>().service;
    _loadVersionList();
  }

  Future<void> _loadVersionList() async {
    print("ran _loadVersionList");
    try {
      setState(() {
        isLoading = true;
      });
      final vers = await _hyperhdr.getAvlVersions();

      final versions = vers.map((version) => {
        ...version,
        'isInstalling': false,
        'isDisabled': false,
      }).toList();
      
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
            );
          },
        ),
      ),
    );
  }
}
