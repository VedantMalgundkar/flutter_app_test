import 'package:flutter/material.dart';
import '../services/http_service.dart';
import 'package:provider/provider.dart';
import '../services/http_service_provider.dart';

class VersionTile extends StatefulWidget {
  final Map<String, dynamic> version;
  final Future<void> Function() onInstallationComplete;
  final void Function(String) onInstalling;

  const VersionTile({
    super.key,
    required this.version,
    required this.onInstallationComplete,
    required this.onInstalling,
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

  Future<void> showConfirmPopUp(String version, String url) async {
    if (widget.version['is_installed']) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Installation"),
        content: Text(
          "Are you sure you want to install this $version version?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Install"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _handleInstall(url);
  }

  Future<void> _handleInstall(String url) async {
    try {
      if (widget.version['is_installed']) {
        return;
      }

      setState(() {
        isInstalling = true;
      });

      widget.onInstalling(widget.version['id']);

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
      widget.onInstallationComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagName = widget.version["tag_name"];
    final versionName = widget.version["release_name"];
    final isAlreadyInstalled = widget.version["is_installed"] == true;
    final downloadUrl = widget.version["browser_download_url"];
    final isDisabled = widget.version["isDisabled"];

    return ListTile(
      title: Text(
        versionName,
        style: TextStyle(fontSize: 15.5),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(tagName, style: TextStyle(fontSize: 12)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isAlreadyInstalled
              ? Theme.of(context).colorScheme.primary
              : null,
          foregroundColor: isAlreadyInstalled
              ? Theme.of(context).colorScheme.onPrimary
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size(100, 30),
        ),
        onPressed: (isDisabled || isInstalling)
            ? null
            : () => showConfirmPopUp(versionName, downloadUrl),
        child: isInstalling
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(isAlreadyInstalled ? "Installed" : "Install"),
      ),
    );
  }
}
