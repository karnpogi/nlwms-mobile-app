import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Uri _uri(String endpoint) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$normalizedBaseUrl$normalizedEndpoint');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }

    return null;
  }

  Future<Map<String, String>> _jsonHeaders() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _multipartHeaders() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    return http.get(
      _uri(endpoint),
      headers: await _jsonHeaders(),
    );
  }

  Future<http.Response> post(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    return http.post(
      _uri(endpoint),
      headers: await _jsonHeaders(),
      body: jsonEncode(body ?? {}),
    );
  }

  Future<http.Response> put(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    return http.put(
      _uri(endpoint),
      headers: await _jsonHeaders(),
      body: jsonEncode(body ?? {}),
    );
  }

  Future<http.Response> patch(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    return http.patch(
      _uri(endpoint),
      headers: await _jsonHeaders(),
      body: jsonEncode(body ?? {}),
    );
  }

  Future<http.Response> delete(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    return http.delete(
      _uri(endpoint),
      headers: await _jsonHeaders(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> deleteAuth(String endpoint) async {
    return http.delete(
      _uri(endpoint),
      headers: await _jsonHeaders(),
    );
  }

  Future<http.Response> postMultipart(
    String endpoint, {
    required String fileField,
    required File file,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(endpoint));

    request.headers.addAll(await _multipartHeaders());

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.add(
      await http.MultipartFile.fromPath(fileField, file.path),
    );

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}