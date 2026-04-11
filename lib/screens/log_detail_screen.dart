import 'package:flutter/material.dart';

import '../models/accomplishment_log_item.dart';

class LogDetailScreen extends StatefulWidget {
  final AccomplishmentLogItem log;

  const LogDetailScreen({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends State<LogDetailScreen> {
  late AccomplishmentLogItem _log;

  final TextEditingController _feedbackCtrl = TextEditingController();
  bool _sendingFeedback = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'verified':
        return 'Verified';
      case 'needs_revision':
        return 'Needs Revision';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'draft':
        return cs.outline;
      case 'submitted':
        return cs.primary;
      case 'under_review':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'needs_revision':
        return Colors.redAccent;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _sendFeedbackReply() async {
    final text = _feedbackCtrl.text.trim();
    if (text.isEmpty || _sendingFeedback) return;

    setState(() => _sendingFeedback = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final newEntry = FeedbackEntry(
        id: DateTime.now().millisecondsSinceEpoch,
        userName: 'You',
        text: text,
        createdAt: DateTime.now(),
        isEdited: false,
      );

      if (!mounted) return;

      setState(() {
        _log = _log.copyWith(
          feedbackEntries: [..._log.feedbackEntries, newEntry],
        );
      });

      _feedbackCtrl.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingFeedback = false);
      }
    }
  }

  Future<void> _editFeedback(FeedbackEntry entry) async {
    final ctrl = TextEditingController(text: entry.text);

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit reply'),
          content: TextField(
            controller: ctrl,
            minLines: 1,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Update your reply',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    final updatedEntries = _log.feedbackEntries.map((item) {
      if (item.id == entry.id) {
        return item.copyWith(
          text: result,
          isEdited: true,
        );
      }
      return item;
    }).toList();

    setState(() {
      _log = _log.copyWith(feedbackEntries: updatedEntries);
    });
  }

  Future<void> _deleteFeedback(FeedbackEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reply?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _log = _log.copyWith(
        feedbackEntries:
            _log.feedbackEntries.where((item) => item.id != entry.id).toList(),
      );
    });
  }

  Widget _buildFeedbackSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final cardBg = cs.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.70,
    );

    final feedbackEntries = _log.feedbackEntries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback & Remarks',
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (feedbackEntries.isEmpty)
            Text(
              'No feedback yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: feedbackEntries.map((entry) {
                final isOwnReply = entry.userName == 'You';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(
                      theme.brightness == Brightness.dark ? 0.25 : 0.60,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.20),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          entry.userName.isNotEmpty
                              ? entry.userName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.userName,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  _timeLabel(entry.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (isOwnReply) ...[
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editFeedback(entry);
                                      } else if (value == 'delete') {
                                        _deleteFeedback(entry);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.text,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (entry.isEdited) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Edited',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _feedbackCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    filled: true,
                    fillColor: cs.surface.withOpacity(
                      theme.brightness == Brightness.dark ? 0.25 : 0.60,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _sendingFeedback ? null : _sendFeedbackReply,
                icon: _sendingFeedback
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusLabel = _statusLabel(_log.status);
    final statusColor = _statusColor(_log.status, cs);

    final cardBg = cs.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.70,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _log.dutyTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _log.remarks.trim().isNotEmpty
                        ? _log.remarks.trim()
                        : 'No remarks provided.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withOpacity(0.45),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildInfoChip(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Date: ${_formatDate(_log.activityDate)}',
                      ),
                      _buildInfoChip(
                        context,
                        icon: Icons.numbers_outlined,
                        label: 'Quantity: ${_log.quantity}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeedbackSection(context),
          ],
        ),
      ),
    );
  }
}