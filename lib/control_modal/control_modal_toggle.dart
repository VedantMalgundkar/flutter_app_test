import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/http_service.dart';
import '../version_info/version_info.dart';
import 'package:provider/provider.dart';
import '../services/http_service_provider.dart';

class ControlModalToggle extends StatefulWidget {
  const ControlModalToggle({super.key});

  @override
  State<ControlModalToggle> createState() => _ControlModalToggleState();
}

class _ControlModalToggleState extends State<ControlModalToggle>
    with SingleTickerProviderStateMixin {
  late final HttpService _hyperhdr;
  Timer? _bootToggleDebounceTimer;
  Timer? _statusToggleDebounceTimer;

  bool _isRunning = false;
  bool _isBootEnabled = false;
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
    _hyperhdr = context.read<HttpServiceProvider>().service;
    _fetchBootStatus();
    _fetchStatus();
    _fetchVersion();
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

  Future<void> _fetchBootStatus() async {
    try {
      final isBootEnbled = await _hyperhdr.isBootEnbled();
      if (!mounted) return;
      setState(() {
        _isBootEnabled = isBootEnbled;
      });
    } on SocketException {
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      print("Status check failed: ${e.toString()}");
      _showMessage("Status check failed: ${e.toString()}");
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
    print("ran _toggleStatus");
    _stopPolling();

    if (mounted) {
      setState(() {
        _isToggling = true;
      });
    }

    try {
      final res = value ? await _hyperhdr.start() : await _hyperhdr.stop();
      print('Toggle response: $res');

      if (res == null) {
        throw Exception('No response from service');
      }

      bool success = false;
      String? message;

      if (res is Map<String, dynamic>) {
        success = res['status'] == 'success';
        message = res['message'] ?? 'Operation completed';
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

  void _onStatusToggleRequested(bool value) {
    _statusToggleDebounceTimer?.cancel(); // Cancel previous

    // Optimistically reflect UI change
    if (mounted) {
      setState(() => _isRunning = value);
    }

    _statusToggleDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _toggleStatus(value);
    });
  }

  Future<void> _toggleBootStatus(bool value) async {
    print("ran _toggleBootStatus");

    try {
      final res = value
          ? await _hyperhdr.enableOnBoot()
          : await _hyperhdr.disableOnBoot();

      if (res == null) {
        throw Exception('No response from service');
      }

      bool success = false;
      String? message;

      if (res is Map<String, dynamic>) {
        success = res['status'] == 'success';
        message = res['message'] ?? 'Operation completed';
      }

      if (success) {
        _showMessage(message!, color: Colors.green);
      } else {
        throw Exception(message ?? 'Operation failed');
      }
    } catch (e) {
      print('Toggle error: $e');
      _showMessage("Toggle Boot failed: ${e.toString()}");
      if (mounted) {
        setState(() => _isBootEnabled = !value);
      }
    }
  }

  void _onBootToggleRequested(bool value) {
    // Cancel any existing debounce timer
    _bootToggleDebounceTimer?.cancel();

    if (mounted) {
      setState(() => _isBootEnabled = value);
    }

    // Start a new debounce timer
    _bootToggleDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _toggleBootStatus(value); // Your actual API call
    });
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
    _statusToggleDebounceTimer?.cancel();
    _bootToggleDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedSlide(
          offset: _isDrawerOpen ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 10,
            ), // space below for shadow to be visible
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.none, // <== important
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isRunning ? "Stop HyperHDR" : "Start HyperHDR"),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 10,
                          ),
                          child: Switch(
                            value: _isRunning,
                            onChanged: _isToggling
                                ? null
                                : _onStatusToggleRequested,
                            // activeColor: Colors.green,
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
                        Text(
                          _isBootEnabled ? "Disable on boot" : "Enable on boot",
                        ),

                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Checkbox(
                              value: _isBootEnabled,
                              onChanged: (value) =>
                                  _onBootToggleRequested(value!),
                            ),
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
                                _toggleDrawer();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VersionInfoPage(),
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
          ),
        ),

        // 3. Drawer Toggle icon
        Positioned(
          top: !_isDrawerOpen ? 0 : null,
          left: 0,
          right: 0,
          bottom: _isDrawerOpen ? 9 : null,
          child: Center(
            child: GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                child: Icon(
                  !_isDrawerOpen
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
