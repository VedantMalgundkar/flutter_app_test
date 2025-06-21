import 'package:flutter/foundation.dart';
import './http_service.dart';

class HttpServiceProvider with ChangeNotifier {
  late HttpService _service;
  Uri? _baseUrl;
  Uri? _hyperUri;

  HttpServiceProvider();

  /// Public getter for the current HttpService
  HttpService get service => _service;

  /// Public getter for current base URL
  Uri? get baseUrl => _baseUrl;
  Uri? get hyperUri => _hyperUri;

  /// Update base URL and reinitialize service
  void updateBaseUrl(Uri url) {
    _baseUrl = url;
    _service = HttpService(baseUrl: url.toString());
    notifyListeners(); // Notifies listening widgets (if any)
  }

  /// Update hyper URI
  void updateHyperUri(Uri url) {
    _hyperUri = url;
    notifyListeners();
  }
}
