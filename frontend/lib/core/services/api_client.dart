import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

/// Thin wrapper around the JRapha backend REST API.
/// Handles base URL, JSON encoding, and attaching the JWT token
/// automatically on every request once the user is logged in.
class ApiClient {
  // Windows desktop / Chrome talking to a locally running backend.
  // If you later run this on an Android emulator, localhost won't
  // reach your machine - use 10.0.2.2 instead. A physical phone needs
  // your PC's LAN IP address (e.g. http://192.168.x.x:5000).
  static const String baseUrl = 'http://localhost:5000/api';

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded is Map && decoded['error'] != null
        ? decoded['error']
        : 'Something went wrong (status ${response.statusCode})';
    throw ApiException(errorMessage, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
