import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import './services/ble_service.dart';
import 'package:http/http.dart' as http;

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final BleService bleService = GetIt.I<BleService>();
  final baseUrl = "http://192.168.0.111:5000";

  @override
  void initState() {
    super.initState();
    // fetchHyperHdrStatus();
    // commonReqFunc('/hyperhdr/current-version', "GET");
    commonReqFunc('/status-hyperhdr', "GET");
    // commonReqFunc('/start-hyperhdr', "POST");
    // commonReqFunc('/stop-hyperhdr', "POST");
    // commonReqFunc('/hyperhdr/install-hyperhdr', "POST", {
    //   "url":
    //       "https://github.com/awawa-dev/HyperHDR/releases/download/v21.0.0.0/HyperHDR-21.0.0.0.bookworm-aarch64.deb",
    // });
  }

  Future<void> commonReqFunc(
    String path,
    String method, [
    Map<String, dynamic>? body,
  ]) async {
    final fullUrl = Uri.parse("$baseUrl$path");
    http.Response response;

    try {
      final headers = {'Content-Type': 'application/json'};

      switch (method.toUpperCase()) {
        case "GET":
          response = await http.get(fullUrl, headers: headers);
          break;
        case "POST":
          response = await http.post(
            fullUrl,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case "PUT":
          response = await http.put(
            fullUrl,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case "DELETE":
          response = await http.delete(
            fullUrl,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        default:
          throw Exception("Unsupported HTTP method: $method");
      }

      if (response.statusCode == 200) {
        print("Success $path : ${response.body}");
      } else {
        print("Failed $path : ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("HIIIIIIIII", style: const TextStyle(fontSize: 24)),
    );
  }
}
