import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/hyperhdr_service.dart';

class HyperhdrToggle extends StatefulWidget {
  const HyperhdrToggle({super.key});

  @override
  State<HyperhdrToggle> createState() => _HyperhdrToggleState();
}

class _HyperhdrToggleState extends State<HyperhdrToggle> {
  final HyperhdrService _hyperhdr = GetIt.I<HyperhdrService>();
  bool _isRunning = false;
  bool _isFetching = true;
  bool _isToggling = false;
  Timer? _pollingTimer;
  bool _isPollingActive = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isToggling && !_isPollingActive) {
        _fetchStatusWithPollingLock();
      }
    });
  }

  Future<void> _fetchStatusWithPollingLock() async {
    if (_isPollingActive) return;
    _isPollingActive = true;
    try {
      await _fetchStatus();
    } finally {
      _isPollingActive = false;
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final running = await _hyperhdr.isRunning();
      if (!mounted) return;
      setState(() {
        _isRunning = running;
        _isFetching = false;
      });
    } on SocketException {
      if (!mounted) return;
      _showMessage("Device not connected.");
      setState(() => _isFetching = false);
    } catch (e) {
      if (!mounted) return;
      _showMessage("Status check failed: ${e.toString()}");
      setState(() => _isFetching = false);
    }
  }

  Future<void> _toggleStatus(bool value) async {
    // Stop polling during toggle
    _pollingTimer?.cancel();

    setState(() {
      _isToggling = true;
      _isRunning = value; // optimistically toggle
    });

    try {
      final res = value ? await _hyperhdr.start() : await _hyperhdr.stop();

      // Debug: Print the response
      print('Toggle response: $res');

      if (res == null) {
        throw Exception('No response from service');
      }

      // Check different possible response formats
      bool success = false;
      String? message;

      if (res is Map<String, dynamic>) {
        success =
            res['status'] == 'success' ||
            res['success'] == true ||
            res['result'] == 'success';
        message = res['message'] ?? res['msg'] ?? 'Operation completed';
      } else {
        // If response is not a map, consider it successful if no exception was thrown
        success = true;
        message = 'Operation completed';
      }

      if (success) {
        _showMessage(message!, color: Colors.green);
        // Verify the actual status after toggle
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchStatus();
      } else {
        throw Exception(message ?? 'Operation failed');
      }
    } catch (e) {
      print('Toggle error: $e');
      _showMessage("Toggle failed: ${e.toString()}");
      // revert toggle if it failed
      if (mounted) {
        setState(() => _isRunning = !value);
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
      // Restart polling
      _startPolling();
    }
  }

  void _showMessage(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const CircularProgressIndicator();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("HyperHDR"),
        const SizedBox(width: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _isToggling ? 0.3 : 1,
              child: Switch(
                value: _isRunning,
                onChanged: _isToggling ? null : _toggleStatus,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
              ),
            ),
            if (_isToggling)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.circle,
          size: 14,
          color: _isRunning ? Colors.green : Colors.red,
        ),
      ],
    );
  }
}
