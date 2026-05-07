import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient apiClient;

  TaskService({required this.apiClient});

  /// NLAMS mobile dashboard/history now reads from accomplishment logs.
  Future<List<Task>> getTasks() async {
    final http.Response res = await apiClient.get('/mobile/logs');

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('GET /mobile/logs FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to load tasks: ${res.statusCode}');
    }

    final dynamic decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic>) {
      final dynamic rawData = decoded['data'] ?? decoded['logs'] ?? [];
      if (rawData is List) {
        return rawData
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return const [];
  }

  /// NLAMS single record now reads from accomplishment log details.
  Future<Task> getTask(int id) async {
    final http.Response res = await apiClient.get('/mobile/logs/$id');

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('GET /mobile/logs/$id FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to load task: ${res.statusCode}');
    }

    final dynamic decoded = jsonDecode(res.body);
    return _taskFromResponse(decoded);
  }

  /// Old task-status updating does not belong to the current NLAMS mobile flow.
  Future<Task> updateTaskStatus(int id, String status) async {
    throw UnsupportedError(
      'updateTaskStatus is from the old task app and is not supported in the current NLAMS mobile API.',
    );
  }

  /// Old task editing does not belong to the current NLAMS mobile flow.
  Future<Task> updateTask(Task task) async {
    throw UnsupportedError(
      'updateTask is from the old task app and is not supported in the current NLAMS mobile API.',
    );
  }

  /// Old task comment logic does not belong to the current NLAMS mobile flow.
  Future<Task> addComment({
    required int taskId,
    required String text,
  }) async {
    throw UnsupportedError(
      'addComment is from the old task app and is not supported in the current NLAMS mobile API.',
    );
  }

  /// Old task comment logic does not belong to the current NLAMS mobile flow.
  Future<Task> updateComment({
    required int taskId,
    required int commentId,
    required String text,
  }) async {
    throw UnsupportedError(
      'updateComment is from the old task app and is not supported in the current NLAMS mobile API.',
    );
  }

  /// Old task comment logic does not belong to the current NLAMS mobile flow.
  Future<Task> deleteComment({
    required int taskId,
    required int commentId,
  }) async {
    throw UnsupportedError(
      'deleteComment is from the old task app and is not supported in the current NLAMS mobile API.',
    );
  }

  Task _taskFromResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map) {
        return Task.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
      }
      if (decoded['log'] is Map) {
        return Task.fromJson(Map<String, dynamic>.from(decoded['log'] as Map));
      }
      if (decoded.containsKey('id')) {
        return Task.fromJson(decoded);
      }
    }

    throw Exception('Unexpected task response shape: $decoded');
  }
}