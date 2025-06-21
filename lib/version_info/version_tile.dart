import 'package:flutter/material.dart';
import '../services/http_service.dart';
import 'package:provider/provider.dart';
import '../services/http_service_provider.dart';

class VersionTile extends StatefulWidget {
  final Map<String, dynamic> version;
  final Future<void> Function() onInstallationComplete;

  const VersionTile({
    super.key,
    required this.version,
    required this.onInstallationComplete,
  });

  @override
  State<VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<VersionTile> {
  late final HttpService _hyperhdr;
  bool isInstalling = false;

  @override
  void initState() {
    super.initState();
    _hyperhdr = context.read<HttpServiceProvider>().service;
  }

  Future<void> _handleInstall(String url) async {
    try {
      setState(() {
        isInstalling = true;
      });

      final response = await _hyperhdr.install(url);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Installation successful"),
        ),
      );
      widget.onInstallationComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) {
        setState(() {
          isInstalling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.version;
    final versionName = version["version"];
    final isAlreadyInstalled = version["is_installed"] == true;
    final assetName = version["assets"]?[0]?["name"] ?? "";
    final downloadUrl = version["assets"]?[0]?["browser_download_url"];

    return ListTile(
      title: Text(assetName),
      subtitle: Text(versionName),
      trailing: SizedBox(
        width: 100,
        height: 36,
        child: ElevatedButton(
          onPressed: (isInstalling || isAlreadyInstalled)
              ? null
              : () => _handleInstall(downloadUrl),
          child: isInstalling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isAlreadyInstalled ? "Installed" : "Install",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ),
    );
  }
}
