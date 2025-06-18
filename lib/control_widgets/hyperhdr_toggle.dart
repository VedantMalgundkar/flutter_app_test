import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/hyperhdr_service.dart';
import '../version_info/version_info.dart';

class HyperhdrToggle extends StatefulWidget {
  const HyperhdrToggle({super.key});

  @override
  State<HyperhdrToggle> createState() => _HyperhdrToggleState();
}

class _HyperhdrToggleState extends State<HyperhdrToggle>
    with SingleTickerProviderStateMixin {
  final HyperhdrService _hyperhdr = GetIt.I<HyperhdrService>();

  bool _isRunning = false;
  bool _isFetching = true;
  bool _isToggling = false;
  bool _isPollingActive = false;
  bool _isDrawerOpen = false;
  String _version = '';

  Timer? _pollingTimer;

  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _drawerAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _drawerController, curve: Curves.easeInOut),
        );
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _drawerController.forward();
      _fetchStatus();
      _startPolling();
      _fetchVersion();
    } else {
      _drawerController.reverse();
      _stopPolling();
    }
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isToggling && !_isPollingActive) {
        _fetchStatusWithPollingLock();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
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

  Future<void> _fetchVersion() async {
    try {
      final versionInfo = await _hyperhdr.getVersion();
      if (!mounted) return;
      setState(() {
        _version = versionInfo?['version'] ?? "---";
      });
    } catch (e) {
      setState(() {
        _version = '---';
      });
    }
  }

  Future<void> _toggleStatus(bool value) async {
    _stopPolling();

    setState(() {
      _isToggling = true;
      _isRunning = value;
    });

    try {
      final res = value ? await _hyperhdr.start() : await _hyperhdr.stop();
      print('Toggle response: $res');

      if (res == null) {
        throw Exception('No response from service');
      }

      bool success = false;
      String? message;

      if (res is Map<String, dynamic>) {
        success =
            res['status'] == 'success' ||
            res['success'] == true ||
            res['result'] == 'success';
        message = res['message'] ?? res['msg'] ?? 'Operation completed';
      } else {
        success = true;
        message = 'Operation completed';
      }

      if (success) {
        _showMessage(message!, color: Colors.green);
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchStatus();
      } else {
        throw Exception(message ?? 'Operation failed');
      }
    } catch (e) {
      print('Toggle error: $e');
      _showMessage("Toggle failed: ${e.toString()}");
      if (mounted) {
        setState(() => _isRunning = !value);
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
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
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Tap outside to close
        if (_isDrawerOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDrawer,
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),

        // 2. Drawer with internal Stack
        AnimatedSlide(
          offset: _isDrawerOpen ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          child: Material(
            elevation: 4,
            color: Colors.white,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isRunning ? "Stop HyperHDR" : "Start HyperHDR",
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 10,
                              ),
                              child: Switch(
                                value: _isRunning,
                                onChanged: _isToggling ? null : _toggleStatus,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text("Version"),
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const VersionInfoPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 10,
                              ),
                              child: Text(_version),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom toggle icon
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleDrawer,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.keyboard_arrow_up, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Toggle icon (only shown when drawer is closed)
        if (!_isDrawerOpen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleDrawer,
                child: Container(
                  // padding: const EdgeInsets.all(8),
                  child: Icon(Icons.keyboard_arrow_down, size: 32),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
