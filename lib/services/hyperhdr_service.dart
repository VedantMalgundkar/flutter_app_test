import 'dart:convert';
import 'package:http/http.dart' as http;

class HyperhdrService {
  final String baseUrl;

  HyperhdrService({required this.baseUrl});

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

  Future<bool> isRunning() async {
    final res = await _request('/status-hyperhdr', 'GET');
    return res?['hyperhdr_status'] == 'active';
  }

  Future<Map<String, dynamic>?> start() async {
    return await _request('/start-hyperhdr', 'POST');
  }

  Future<Map<String, dynamic>?> stop() async {
    return await _request('/stop-hyperhdr', 'POST');
  }

  Future<bool> install(String url) async {
    final res = await _request(
      '/hyperhdr/install-hyperhdr',
      'POST',
      body: {'url': url},
    );
    return res != null;
  }
}
