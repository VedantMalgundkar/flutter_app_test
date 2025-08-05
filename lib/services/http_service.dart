import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  final String baseUrl;

  HttpService({required this.baseUrl});

  Future<Map<String, dynamic>?> _request(
    String path,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final fullUrl = Uri.parse("$baseUrl$path");
    http.Response response;
    final headers = {'Content-Type': 'application/json'};

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(fullUrl, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'PUT':
        response = await http.put(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>?> setHostname(String hostname) async {
    return await _request(
      '/set-unique-hostname',
      'POST',
      body: {'hostname': hostname},
    );
  }

  Future<bool> isRunning() async {
    final res = await _request('/status-hyperhdr', 'GET');
    return res?['hyperhdr_status'] == 'active';
  }

  Future<bool> isBootEnbled() async {
    final res = await _request('/boot-status-hyperhdr', 'GET');
    return res?['is_enabled_on_boot'];
  }

  Future<Map<String, dynamic>?> start() async {
    return await _request('/start-hyperhdr', 'POST');
  }

  Future<Map<String, dynamic>?> enableOnBoot() async {
    return await _request('/enable-boot-hyperhdr', 'POST');
  }

  Future<Map<String, dynamic>?> stop() async {
    return await _request('/stop-hyperhdr', 'POST');
  }

  Future<Map<String, dynamic>?> disableOnBoot() async {
    return await _request('/disable-boot-hyperhdr', 'POST');
  }

  Future<Map<String, dynamic>?> getVersion() async {
    return await _request('/hyperhdr/current-version', 'GET');
  }

  Future<List<Map<String, dynamic>>> getAvlVersions() async {
    final response = await _request('/hyperhdr/avl-versions', 'GET');

    final versions = response?['versions'];

    if (versions is List) {
      return versions.map((v) => Map<String, dynamic>.from(v)).toList();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getConnectedWifi() async {
    return await _request('/get-connected-wifi', 'GET');
  }

  Future<Map<String, dynamic>?> scanNearbyNetworks() async {
    return await _request('/scan-wifi', 'GET');
  }

  Future<Map<String, dynamic>?> getMac() async {
    return await _request('/get-mac', 'GET');
  }
  
  Future<Map<String, dynamic>?> install(String url) async {
    print("base url ${this.baseUrl}");
    final res = await _request(
      '/hyperhdr/install-hyperhdr',
      'POST',
      body: {'url': url},
    );
    return res;
  }

  Future<Map<String, dynamic>?> getLedBrightness() async {
    return await _request('/led/get-brightness', 'GET');
  }
  
  Future<Map<String, dynamic>?> adjustLedBrightness(int brightness) async {
    return await _request('/led/adjust-brightness', 'POST', body : {
      'brightness': brightness,
    });
  }

}
