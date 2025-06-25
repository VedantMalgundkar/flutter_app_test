import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/http_service.dart';
import '../../services/http_service_provider.dart';

class HyperhdrServiceTile extends StatefulWidget {
  final Map<String, dynamic> device;
  final Uri? globalUri;
  final void Function(Map<String, dynamic> device)? onSelect;

  const HyperhdrServiceTile({
    super.key,
    required this.device,
    required this.globalUri,
    this.onSelect,
  });

  @override
  State<HyperhdrServiceTile> createState() => _HyperhdrServiceTileState();
}

class _HyperhdrServiceTileState extends State<HyperhdrServiceTile> {
  late HttpService _hyperhdr;
  bool isLoading = false;
  late TextEditingController _controller;
  bool shouldEditVisible = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HttpServiceProvider>();
    if (provider.baseUrl == null) {
      shouldEditVisible = false;
    } else {
      shouldEditVisible = true;
      _hyperhdr = provider.service;
    }

    _controller = TextEditingController(
      text: widget.device["label"].split("-")[0].trim(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveName() {
    setState(() => isEditing = false);
    if (widget.device["label"].split("-")[0].trim().toLowerCase() !=
        _controller.text.trim().toLowerCase()) {
      widget.device["label"] = _controller.text;
      updateHostName(_controller.text);
    }
  }

  Future<void> updateHostName(String hostname) async {
    setState(() => isLoading = true);

    try {
      final result = await _hyperhdr.setHostname(hostname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hostname updated successfully")),
        );
      }
    } catch (e) {
      debugPrint("Failed to update hostname : $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update hostname")));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.globalUri == widget.device["url"];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xfffffbff),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: Row(
          children: [
            isEditing
                ? Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onSubmitted: (_) => _saveName(),
                    ),
                  )
                : Expanded(child: Text(_controller.text)),
            if (shouldEditVisible)
              IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit),
                onPressed: () {
                  if (isEditing) {
                    _saveName();
                  } else {
                    setState(() => isEditing = true);
                  }
                },
              ),
          ],
        ),
        trailing: isSelected
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  minimumSize: const Size(100, 30),
                ),
                child: const Text("Connect"),
                onPressed: () => widget.onSelect?.call(widget.device),
              ),
      ),
    );
  }
}
