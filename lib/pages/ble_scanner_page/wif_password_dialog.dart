import 'package:flutter/material.dart';

class WifiPasswordDialog extends StatefulWidget {
  final String ssid;
  final Future<void> Function(String ssid, String password) onSubmit;

  const WifiPasswordDialog({
    Key? key,
    required this.ssid,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<WifiPasswordDialog> createState() => _WifiPasswordDialogState();
}

class _WifiPasswordDialogState extends State<WifiPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;

  Future<void> _handleSubmit() async {
    setState(() => _loading = true);
    try {
      await widget.onSubmit(widget.ssid, _passwordController.text);
      // if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.ssid,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 7.0, bottom: 15.0),
        child: TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: "Password",
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _handleSubmit,
          child: SizedBox(
            width: 54,
            child: Center(
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : const Text("Connect"),
            ),
          ),
        ),
      ],
    );
  }
}
