// task_comment.dart
class TaskComment {
  final int id;
  final int userId;

  /// Always show something usable in UI
  final String userName;

  /// Comment body (Laravel uses 'text' in your routes)
  final String text;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  static String _toStr(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  /// Supports common Laravel shapes:
  /// - { user_name: "Ed" }
  /// - { user: { name: "Ed" } }
  /// - { user: { full_name: "Ed" } }
  static String _extractUserName(Map<String, dynamic> json) {
    final direct = json['user_name'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();

    final user = json['user'];
    if (user is Map) {
      final m = Map<String, dynamic>.from(user);
      final name = m['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();

      final fullName = m['full_name'] ?? m['fullname'];
      if (fullName is String && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
    }

    // sometimes APIs send displayName, username, etc.
    final alt = json['name'] ?? json['username'] ?? json['display_name'];
    final altStr = _toStr(alt).trim();
    return altStr.isNotEmpty ? altStr : 'User';
  }

  /// Supports common Laravel shapes for body:
  /// - text
  /// - comment/body/message
  static String _extractText(Map<String, dynamic> json) {
    final raw = json['text'] ?? json['comment'] ?? json['body'] ?? json['message'];
    return _toStr(raw).trim();
  }

    bool get isEdited {
    if (updatedAt == null) return false;

    // Laravel sets created_at and updated_at equal on create.
    // Only mark edited if updated_at is meaningfully later.
    return updatedAt!.isAfter(createdAt.add(const Duration(seconds: 2)));
  }

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      userName: _extractUserName(json),
      text: _extractText(json),
      createdAt: _toDate(json['created_at']),
      updatedAt: json['updated_at'] != null ? _toDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
