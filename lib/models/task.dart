class Task {
  final int id;
  final int? userId;
  final String title;
  final String? description;
  final String status;
  final String? priority;
  final String? coverColor;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
  });

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

  static String _normalizeStatus(dynamic rawStatus) {
    final status = _toStr(rawStatus, fallback: 'pending').toLowerCase().trim();

    switch (status) {
      case 'verified':
      case 'approved':
      case 'done':
        return 'done';

      case 'submitted':
      case 'under_review':
      case 'in_review':
      case 'review':
      case 'in_progress':
        return 'in_progress';

      case 'returned':
      case 'needs_revision':
      case 'revision':
      case 'pending':
      case 'draft':
      default:
        return 'pending';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final dynamic dutyTemplate = json['duty_template'];
    final dynamic titleFromRelation = dutyTemplate is Map<String, dynamic>
        ? dutyTemplate['title']
        : null;

    final dynamic descriptionFromRelation = dutyTemplate is Map<String, dynamic>
        ? dutyTemplate['description']
        : null;

    final dynamic remarks = json['remarks'];

    return Task(
      id: _toInt(json['id']),
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      title: _toStr(
        titleFromRelation ?? json['title'],
        fallback: 'Untitled Log',
      ),
      description: _toStr(
        remarks ?? descriptionFromRelation ?? json['description'],
        fallback: '',
      ).trim().isEmpty
          ? null
          : _toStr(
              remarks ?? descriptionFromRelation ?? json['description'],
              fallback: '',
            ),
      status: _normalizeStatus(json['status']),
      priority: json['priority'] != null ? _toStr(json['priority']).trim() : null,
      coverColor: json['cover_color'] as String?,
      dueDate: _toNullableDate(
        json['activity_date'] ?? json['due_date'],
      ),
      createdAt: _toNullableDate(json['created_at']),
      updatedAt: _toNullableDate(json['updated_at']),
    );
  }

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
    };
  }

  factory Task.fromStorageJson(Map<String, dynamic> json) {
    return Task(
      id: _toInt(json['id']),
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      title: _toStr(json['title']),
      description: json['description'] as String?,
      status: _toStr(json['status'], fallback: 'pending'),
      priority: json['priority'] as String?,
      coverColor: json['cover_color'] as String?,
      dueDate: _toNullableDate(json['due_date']),
      createdAt: _toNullableDate(json['created_at']),
      updatedAt: _toNullableDate(json['updated_at']),
    );
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
    );
  }
}