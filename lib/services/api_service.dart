import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Exception thrown when an API call fails.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Base HTTP service used by all feature-specific services.
/// Handles Authorization headers, JSON encoding/decoding, and error mapping.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Build full URI from a path segment.
  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  /// Common headers including auth token if available.
  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Core HTTP Methods ──────────────────────────────────────────────────

  /// Perform a GET request.
  Future<dynamic> get(String path, {String? token}) async {
    final response = await _client
        .get(_uri(path), headers: _headers(token: token))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  /// Perform a POST request with a JSON body.
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    final response = await _client
        .post(_uri(path),
            headers: _headers(token: token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  /// Perform a PUT request with a JSON body.
  Future<dynamic> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    final response = await _client
        .put(_uri(path),
            headers: _headers(token: token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  /// Perform a DELETE request.
  Future<dynamic> delete(String path, {String? token}) async {
    final response = await _client
        .delete(_uri(path), headers: _headers(token: token))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  // ─── Response Handling ──────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response) {
    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } else if (response.statusCode == 401) {
      throw ApiException(401, 'Non autorisé. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw ApiException(404, 'Ressource introuvable.');
    } else {
      // Try to extract a message from the body
      String msg;
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        msg = json['message'] as String? ?? 'Erreur serveur.';
      } catch (_) {
        msg = body.isNotEmpty ? body : 'Erreur inconnue.';
      }
      throw ApiException(response.statusCode, msg);
    }
  }

  void dispose() => _client.close();
}
