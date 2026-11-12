import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

// A file read from the phone, ready to upload as an attachment.
class UploadFile {
  const UploadFile({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;

  bool get isImage => contentType.startsWith('image/');
}

// Low level HTTP helper. Adds the base URL, the JSON headers and the token.
// Returns the decoded JSON (or null when the response has no body).
class ApiClient {
  // main.dart sets this to go back to the login screen after a 401.
  static void Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 10);
  // Receipt uploads and downloads (up to 10 MB) need more time on a phone.
  static const Duration _fileTimeout = Duration(seconds: 60);

  static Future<dynamic> get(String path) => _send('GET', path);

  static Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);

  static Future<dynamic> put(String path, Object? body) =>
      _send('PUT', path, body);

  static Future<dynamic> patch(String path, Object? body) =>
      _send('PATCH', path, body);

  static Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body);

  // Sends one file as multipart/form-data, in the part named "file".
  // The body is built by hand so the part's Content-Type is exactly the file's type.
  static Future<dynamic> uploadFile(String path, UploadFile file) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final boundary = 'evce-${DateTime.now().microsecondsSinceEpoch}';
    // Quotes and line breaks would break the header, so they are replaced.
    final safeName = file.filename.replaceAll(RegExp(r'["\\r\n]'), '_');

    final body = BytesBuilder()
      ..add(utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$safeName"\r\n'
        'Content-Type: ${file.contentType}\r\n\r\n',
      ))
      ..add(file.bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final headers = <String, String>{
      'Content-Type': 'multipart/form-data; boundary=$boundary',
    };
    _addToken(headers);

    final response = await _run(
      () => http.post(uri, headers: headers, body: body.takeBytes()),
      _fileTimeout,
    );
    await _checkStatus(response, path);
    return _decode(response);
  }

  // Downloads the raw bytes of a file (for example an attachment).
  static Future<Uint8List> getBytes(String path) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = <String, String>{};
    _addToken(headers);

    final response = await _run(
      () => http.get(uri, headers: headers),
      _fileTimeout,
    );
    await _checkStatus(response, path);
    return response.bodyBytes;
  }

  static Future<dynamic> _send(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$apiBaseUrl$path');

    final headers = <String, String>{'Content-Type': 'application/json'};
    _addToken(headers);

    final encodedBody = body == null ? null : jsonEncode(body);

    final response = await _run(
      () => _doRequest(method, uri, headers, encodedBody),
      _timeout,
    );
    await _checkStatus(response, path);
    return _decode(response);
  }

  static void _addToken(Map<String, String> headers) {
    if (Session.token != null) {
      headers['Authorization'] = 'Bearer ${Session.token}';
    }
  }

  // Runs one request and turns network problems into ApiException(0).
  static Future<http.Response> _run(
    Future<http.Response> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on SocketException {
      throw ApiException(0, 'network');
    } on TimeoutException {
      throw ApiException(0, 'network');
    } on http.ClientException {
      throw ApiException(0, 'network');
    }
  }

  // Throws for error statuses. A 401 outside the login/register calls clears the session.
  static Future<void> _checkStatus(http.Response response, String path) async {
    if (response.statusCode < 400) return;

    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    final message =
        _errorMessageFrom(text) ?? response.reasonPhrase ?? 'Request failed';

    // A 401 outside the login/register calls means the token is no longer valid.
    if (response.statusCode == 401 && !path.startsWith('/api/auth/')) {
      await Session.clear();
      onUnauthorized?.call();
    }

    throw ApiException(response.statusCode, message);
  }

  // The API sends UTF-8 JSON. Decode the bytes so Turkish letters work.
  static dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
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
        return http.delete(uri, headers: headers, body: body);
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
