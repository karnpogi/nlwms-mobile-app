import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient apiClient;

  TaskService({required this.apiClient});

  /// ✅ List endpoint (summary list)
  /// IMPORTANT: Do NOT rely on this for comments.
  /// Task details must always come from GET /tasks/{id}.
  Future<List<Task>> getTasks() async {
    final http.Response res = await apiClient.get('/tasks');

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('GET /tasks FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to load tasks: ${res.statusCode}');
    }

    final dynamic decoded = jsonDecode(res.body);

    // Common Laravel shape: { data: [...] }
    if (decoded is Map<String, dynamic>) {
      final List<dynamic> data = (decoded['data'] ?? []) as List<dynamic>;
      return data
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // Fallback: raw list
    if (decoded is List) {
      return decoded
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return const [];
  }

  /// ✅ Single-task endpoint (must include comments)
  Future<Task> getTask(int id) async {
    final http.Response res = await apiClient.get('/tasks/$id');

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('GET /tasks/$id FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to load task: ${res.statusCode}');
    }

    final dynamic decoded = jsonDecode(res.body);
    return _taskFromResponse(decoded);
  }

  /// ✅ Mobile: update status only
  /// PATCH /tasks/{id}/status  { status: pending|in_progress|done }
  Future<Task> updateTaskStatus(int id, String status) async {
    final http.Response res = await apiClient.patch(
      '/tasks/$id/status',
      {'status': status},
    );

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('PATCH /tasks/$id/status FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to update task status: ${res.statusCode}');
    }

    // Even if backend returns something, we still normalize by refetching.
    return getTask(id);
  }

  /// Optional: if you still allow limited edits on mobile later.
  /// (If your rules say "no mobile task editing", you can delete this.)
  Future<Task> updateTask(Task task) async {
    final http.Response res = await apiClient.put(
      '/tasks/${task.id}',
      task.toJson(),
    );

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('PUT /tasks/${task.id} FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to update task: ${res.statusCode}');
    }

    return getTask(task.id);
  }

  // ----------------------------
  // ✅ Comments: always refetch
  // ----------------------------

  /// ✅ Add comment → refetch task → return updated task
  Future<Task> addComment({
    required int taskId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return getTask(taskId);

    final http.Response res = await apiClient.post(
      '/tasks/$taskId/comments',
      {'text': trimmed},
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      // ignore: avoid_print
      print('POST /tasks/$taskId/comments FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to add comment: ${res.statusCode}');
    }

    // ✅ One truth: re-fetch from task details endpoint
    return getTask(taskId);
  }

  /// ✅ Edit comment → refetch task → return updated task
  Future<Task> updateComment({
    required int taskId,
    required int commentId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return getTask(taskId);

    final http.Response res = await apiClient.patch(
      '/tasks/$taskId/comments/$commentId',
      {'text': trimmed},
    );

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('PATCH /tasks/$taskId/comments/$commentId FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to update comment: ${res.statusCode}');
    }

    return getTask(taskId);
  }

  /// ✅ Delete comment → refetch task → return updated task
  Future<Task> deleteComment({
    required int taskId,
    required int commentId,
  }) async {
    final http.Response res = await apiClient.delete(
      '/tasks/$taskId/comments/$commentId',
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      // ignore: avoid_print
      print('DELETE /tasks/$taskId/comments/$commentId FAILED: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
      throw Exception('Failed to delete comment: ${res.statusCode}');
    }

    return getTask(taskId);
  }

  // ----------------------------
  // Helpers
  // ----------------------------

  /// Handles typical Laravel shapes:
  /// - { data: { ...task... } }
  /// - { task: { ...task... } }
  /// - { ...task... } (raw)
  Task _taskFromResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map) {
        return Task.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
      }
      if (decoded['task'] is Map) {
        return Task.fromJson(Map<String, dynamic>.from(decoded['task'] as Map));
      }
      // Raw task map
      if (decoded.containsKey('id') && decoded.containsKey('title')) {
        return Task.fromJson(decoded);
      }
    }

    throw Exception('Unexpected task response shape: $decoded');
  }
}
