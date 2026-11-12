import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:roommate_expense_app/config.dart';
import 'package:roommate_expense_app/session.dart';

// An error returned by the API (or a network error).
// statusCode 0 means the server could not be reached.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// Low level HTTP helper. Adds the base URL, the JSON headers and the token.
// Returns the decoded JSON (or null when the response has no body).
class ApiClient {
  // main.dart sets this to go back to the login screen after a 401.
  static void Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 10);

  static Future<dynamic> get(String path) => _send('GET', path);

  static Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);

  static Future<dynamic> put(String path, Object? body) =>
      _send('PUT', path, body);

  static Future<dynamic> patch(String path, Object? body) =>
      _send('PATCH', path, body);

  static Future<dynamic> delete(String path) => _send('DELETE', path);

  static Future<dynamic> _send(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$apiBaseUrl$path');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (Session.token != null) {
      headers['Authorization'] = 'Bearer ${Session.token}';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    final http.Response response;
    try {
      response = await _doRequest(method, uri, headers, encodedBody)
          .timeout(_timeout);
    } on SocketException {
      throw ApiException(0, 'network');
    } on TimeoutException {
      throw ApiException(0, 'network');
    } on http.ClientException {
      throw ApiException(0, 'network');
    }

    // The API sends UTF-8 JSON. Decode the bytes so Turkish letters work.
    final text = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 400) {
      final message =
          _errorMessageFrom(text) ?? response.reasonPhrase ?? 'Request failed';

      // A 401 outside the login/register calls means the token is no longer valid.
      if (response.statusCode == 401 && !path.startsWith('/api/auth/')) {
        await Session.clear();
        onUnauthorized?.call();
      }

      throw ApiException(response.statusCode, message);
    }

    if (text.trim().isEmpty) return null;
    return jsonDecode(text);
  }

  static Future<http.Response> _doRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: body);
      case 'PUT':
        return http.put(uri, headers: headers, body: body);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: body);
      default:
        return http.delete(uri, headers: headers);
    }
  }

  // The API's errors look like {"status": 404, "message": "..."}.
  static String? _errorMessageFrom(String text) {
    try {
      final json = jsonDecode(text);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
