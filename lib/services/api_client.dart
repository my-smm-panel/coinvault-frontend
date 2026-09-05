import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';

/// Lightweight REST client for the CoinVault backend.
/// Handles JSON, auth token header and error parsing.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  /// Set the JWT returned after login (persist this in the app).
  set token(String? value) => _token = value;
  String? get token => _token;

  Map<String, String> _headers({bool auth = true}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('${ApiConfig.apiBaseUrl}$path'),
        headers: _headers(auth: auth));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(Uri.parse('${ApiConfig.apiBaseUrl}$path'),
        headers: _headers(auth: auth), body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.put(Uri.parse('${ApiConfig.apiBaseUrl}$path'),
        headers: _headers(auth: auth), body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body,
      bool auth = true]) async {
    final res = await http.patch(Uri.parse('${ApiConfig.apiBaseUrl}$path'),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(Uri.parse('${ApiConfig.apiBaseUrl}$path'),
        headers: _headers(auth: auth));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final data = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(res.statusCode, (data is Map && data['error'] is String) ? data['error'] : 'Request failed');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
