// task.dart
import 'task_comment.dart';

// NOTE: Subtasks disabled for now – no Subtask import.
// import 'subtask.dart';

class Task {
  final int id;
  final int? userId;
  final String title;
  final String? description;

  /// 'pending', 'in_progress', 'done'
  final String status;

  /// 'Low', 'Medium', 'High' (UI label; backend may send lowercased too)
  final String? priority;

  /// Hex like "#1e40af" / "#111827" (nullable)
  /// Backend key: cover_color
  final String? coverColor;

  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// ✅ Single source of truth: task_comments table → returned as "comments"
  final List<TaskComment> comments;

  Task({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.status = 'pending',
    this.priority,
    this.coverColor,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    List<TaskComment>? comments,
  }) : comments = comments ?? const [];

  int get commentsCount => comments.length;

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toNullableDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static String _toStr(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  /// Handles:
  /// - comments: [ ... ]
  /// - task_comments: [ ... ] (if older API)
  /// - comments: { data: [ ... ] } (if paginated resource)
  static List<TaskComment> _parseComments(dynamic raw) {
    if (raw == null) return const [];

    // paginated style: { data: [...] }
    if (raw is Map && raw['data'] is List) {
      raw = raw['data'];
    }

    if (raw is List) {
      final out = <TaskComment>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          out.add(TaskComment.fromJson(e));
        } else if (e is Map) {
          out.add(TaskComment.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    }

    return const [];
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final dynamic rawComments =
        json.containsKey('comments') ? json['comments'] : json['task_comments'];

    return Task(
      id: _toInt(json['id']),
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      title: _toStr(json['title'], fallback: ''),
      description: (json['description'] as String?),

      status: _toStr(json['status'], fallback: 'pending'),

      // priority might be null / string / number
      priority: json['priority'] != null ? _toStr(json['priority']).trim() : null,

      // cover color might be null
      coverColor: json['cover_color'] as String?,

      dueDate: _toNullableDate(json['due_date']),
      createdAt: _toNullableDate(json['created_at']),
      updatedAt: _toNullableDate(json['updated_at']),

      comments: _parseComments(rawComments),
    );
  }

  /// Payload for task updates (keep minimal; DO NOT include comments)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      if (priority != null && priority!.trim().isNotEmpty) 'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      if (coverColor != null && coverColor!.trim().isNotEmpty)
        'cover_color': coverColor,
    };
  }

  /// For local persistence (optional)
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      if (priority != null) 'priority': priority,
      'cover_color': coverColor,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? coverColor,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskComment>? comments,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      coverColor: coverColor ?? this.coverColor,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
    );
  }
}
