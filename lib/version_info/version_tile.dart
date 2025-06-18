import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/hyperhdr_service.dart';

class VersionTile extends StatefulWidget {
  final Map<String, dynamic> version;

  const VersionTile({super.key, required this.version});

  @override
  State<VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<VersionTile> {
  final HyperhdrService _hyperhdr = GetIt.I<HyperhdrService>();
  bool isInstalling = false;

  // Future<void> _handleInstall(url) async {
  //   print("url $url");
  //   setState(() => isInstalling = true);
  //   try {
  //     await Future.delayed(const Duration(seconds: 4));
  //   } finally {
  //     if (mounted) setState(() => isInstalling = false);
  //   }
  // }

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
    final assetName = version["assets"]?[0]?["name"] ?? "";
    final downloadUrl = version["assets"]?[0]?["browser_download_url"];

    return ListTile(
      title: Text(assetName),
      subtitle: Text(versionName),
      trailing: SizedBox(
        width: 100,
        height: 36,
        child: ElevatedButton(
          onPressed: isInstalling ? null : () => _handleInstall(downloadUrl),
          child: isInstalling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Install"),
        ),
      ),
    );
  }
}
