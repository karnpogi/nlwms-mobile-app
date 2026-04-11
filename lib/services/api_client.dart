import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(String path) async {
    return http.get(_uri(path), headers: await _headers(json: false));
  }

  Future<http.Response> post(String path, Map<String, dynamic> data) async {
    return http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> data) async {
    return http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> patch(String path, Map<String, dynamic> data) async {
    return http.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> delete(String path) async {
    return http.delete(_uri(path), headers: await _headers(json: false));
  }

  // ============================
  // NEW: Multipart upload (avatar)
  // ============================
  Future<http.Response> postMultipart(
    String path, {
    required String fileField,
    required File file,
    Map<String, String>? fields,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', _uri(path));

    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.add(
      await http.MultipartFile.fromPath(fileField, file.path),
    );

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // Some backends require DELETE with auth headers (yours does)
  Future<http.Response> deleteAuth(String path) async {
    return http.delete(_uri(path), headers: await _headers(json: false));
  }
}