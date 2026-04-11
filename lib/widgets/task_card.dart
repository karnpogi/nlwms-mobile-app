import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'in_progress':
        return cs.tertiary;
      case 'done':
        return cs.primary;
      case 'pending':
      default:
        return cs.secondary;
    }
  }

  Color _priorityColor(String? p, ColorScheme cs) {
    switch ((p ?? '').toLowerCase()) {
      case 'high':
        return cs.error;
      case 'medium':
        return cs.tertiary;
      case 'low':
      default:
        return cs.secondary;
    }
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns label + kind for due date chip.
  /// kind: overdue / today / future
  ({String label, String kind})? _dueChip(DateTime? due) {
    if (due == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);

    if (d.isBefore(today)) return (label: 'Overdue', kind: 'overdue');
    if (d == today) return (label: 'Today', kind: 'today');
    return (label: _formatDateShort(due), kind: 'future');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusLabel = _statusLabel(task.status);
    final statusColor = _statusColor(task.status, cs);
    final priorityColor = _priorityColor(task.priority, cs);
    final due = _dueChip(task.dueDate);

    final bg = cs.surface;
    final border = cs.outlineVariant.withOpacity(0.35);

    // If you have a comments count in your model, wire it here.
    // Option 1 (recommended): add `int commentsCount` to Task.
    // Option 2 (safe default): keep 0 and hide chip when 0.
    final int commentsCount = _tryGetCommentsCount(task);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.10 : 0.06,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top strip (status color)
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ],
                  ),

                  // Description
                  if (task.description != null && task.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        icon: Icons.circle,
                        label: statusLabel,
                        fg: statusColor,
                        border: statusColor.withOpacity(0.25),
                        bg: statusColor.withOpacity(0.10),
                      ),
                      _Pill(
                        icon: Icons.flag_outlined,
                        label: (task.priority ?? 'Low'),
                        fg: priorityColor,
                        border: priorityColor.withOpacity(0.25),
                        bg: priorityColor.withOpacity(0.10),
                      ),
                      if (due != null)
                        _Pill(
                          icon: Icons.event,
                          label: due.label,
                          fg: _dueColor(due.kind, cs),
                          border: _dueColor(due.kind, cs).withOpacity(0.25),
                          bg: _dueColor(due.kind, cs).withOpacity(0.10),
                        ),
                      if (commentsCount > 0)
                        _Pill(
                          icon: Icons.chat_bubble_outline,
                          label: commentsCount.toString(),
                          fg: cs.onSurfaceVariant,
                          border: cs.outlineVariant.withOpacity(0.35),
                          bg: cs.surfaceVariant.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.55),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _dueColor(String kind, ColorScheme cs) {
    switch (kind) {
      case 'overdue':
        return cs.error;
      case 'today':
        return cs.tertiary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  // --- Safe comment count reader ---
  // If Task has `commentsCount`, use it.
  // If not, return 0 (and the comment chip will stay hidden).
  static int _tryGetCommentsCount(Task task) {
    try {
      final dynamic t = task;
      final dynamic v = t.commentsCount;
      if (v is int) return v;
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final Color border;

  const _Pill({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
