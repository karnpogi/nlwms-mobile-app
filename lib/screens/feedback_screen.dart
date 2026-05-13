import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/task_service.dart';
import 'log_accomplishment_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final TaskService? taskService;
  final int? initialLogId;

  const FeedbackScreen({
    super.key,
    this.taskService,
    this.initialLogId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final TaskService _taskService;
  bool _isLoading = true;
  String? _error;
  List<_ReturnedFeedbackItem> _items = [];

  @override
  void initState() {
    super.initState();
    _taskService = widget.taskService ?? TaskService(apiClient: ApiClient(baseUrl: 'http://10.0.2.2:8000/api'));
    _loadReturnedFeedback();
  }

  Future<void> _loadReturnedFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      /*
      |--------------------------------------------------------------------------
      | Important:
      | Use the same source as the dashboard Recent Returned Logs.
      | The old version used weekly-report/history, which could show a different
      | result from the dashboard because it depends on returned weekly ARs.
      |--------------------------------------------------------------------------
      */
      final response = await _taskService.apiClient.get('/mobile/logs?status=returned&attached=1');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
        throw Exception('Failed to load returned logs.');
      }

      final rawLogs = decoded['data'];
      final returnedItems = <_ReturnedFeedbackItem>[];

      if (rawLogs is List) {
        for (final rawLog in rawLogs) {
          if (rawLog is! Map) continue;

          final log = Map<String, dynamic>.from(rawLog);
          final logStatus = log['status']?.toString().toLowerCase() ?? '';
          final requiresRevision = log['requires_revision'] == true ||
              log['requires_revision']?.toString() == '1';

          final revisionFeedback =
              log['revision_feedback']?.toString().trim() ?? '';
          final fallbackFeedback = log['feedback']?.toString().trim() ?? '';

          final shouldShow = logStatus == 'returned' ||
              requiresRevision ||
              revisionFeedback.isNotEmpty ||
              fallbackFeedback.isNotEmpty;

          if (!shouldShow) continue;

          final activityDate = log['activity_date']?.toString();
          final weekStart = log['week_start']?.toString() ??
              _startOfWeekText(activityDate);
          final weekEnd = log['week_end']?.toString() ??
              _endOfWeekText(activityDate);

          returnedItems.add(
            _ReturnedFeedbackItem(
              logId: _toIntOrNull(log['id']),
              submissionId: log['accomplishment_submission_id'] ??
                  log['submission_id'],
              weekStart: weekStart,
              weekEnd: weekEnd,
              dayLabel: _dayLabel(activityDate),
              activityDate: activityDate,
              title: log['duty_template'] is Map
                  ? (log['duty_template']['title']?.toString() ??
                      log['duty_title']?.toString() ??
                      'Untitled duty')
                  : (log['duty_title']?.toString() ?? 'Untitled duty'),
              quantity: log['quantity']?.toString() ?? '0',
              remarks: log['remarks']?.toString().trim() ?? '',
              revisionFeedback: revisionFeedback.isNotEmpty
                  ? revisionFeedback
                  : fallbackFeedback.isNotEmpty
                      ? fallbackFeedback
                      : 'This accomplishment log was returned for revision.',
              status: logStatus.isNotEmpty ? logStatus : 'returned',
              rawLog: log,
            ),
          );
        }
      }

      if (!mounted) return;

      final visibleItems = widget.initialLogId == null
          ? returnedItems
          : returnedItems
              .where((item) => item.logId == widget.initialLogId)
              .toList();

      setState(() => _items = visibleItems);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String? _startOfWeekText(String? value) {
    final date = _parseDate(value);
    if (date == null) return null;

    final start = date.subtract(Duration(days: date.weekday - 1));
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  String? _endOfWeekText(String? value) {
    final date = _parseDate(value);
    if (date == null) return null;

    final end = date.add(Duration(days: 7 - date.weekday));
    return '${end.year.toString().padLeft(4, '0')}-'
        '${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
  }

  String? _dayLabel(String? value) {
    final date = _parseDate(value);
    if (date == null) return null;

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[date.weekday - 1];
  }

  int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _formatDateText(String? value) {
    if (value == null || value.trim().isEmpty) return '—';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _statusLabel(String value) {
    final status = value.trim().toLowerCase();
    if (status.isEmpty) return 'Returned';
    return status[0].toUpperCase() + status.substring(1);
  }

  void _openSubmissionDetails(_ReturnedFeedbackItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogAccomplishmentScreen(
          existingLog: item.rawLog,
        ),
      ),
    ).then((_) => _loadReturnedFeedback());
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.assignment_return_outlined,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Returned Logs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These are accomplishment logs returned by your Unit Head for correction.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(_ReturnedFeedbackItem item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final weekStart = _formatDateText(item.weekStart);
    final weekEnd = _formatDateText(item.weekEnd);
    final activityDate = _formatDateText(item.activityDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: Text(
                    _statusLabel(item.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$weekStart - $weekEnd',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.dayLabel ?? 'Activity'} • $activityDate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text('Quantity: ${item.quantity}'),
            if (item.remarks.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Remarks: ${item.remarks}'),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revision Note',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.revisionFeedback,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openSubmissionDetails(item),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Revise / View Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Returned Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReturnedFeedback,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(
                    'Returned Logs',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review accomplishment logs returned for revision.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIntro(context),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: theme.colorScheme.errorContainer.withOpacity(0.55),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  else if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No returned feedback at the moment.'),
                      ),
                    )
                  else
                    ..._items.map(_buildFeedbackCard),
                ],
              ),
      ),
    );
  }
}

class _ReturnedFeedbackItem {
  final int? logId;
  final dynamic submissionId;
  final String? weekStart;
  final String? weekEnd;
  final String? dayLabel;
  final String? activityDate;
  final String title;
  final String quantity;
  final String remarks;
  final String revisionFeedback;
  final String status;
  final Map<String, dynamic> rawLog;

  const _ReturnedFeedbackItem({
    required this.logId,
    required this.submissionId,
    required this.weekStart,
    required this.weekEnd,
    required this.dayLabel,
    required this.activityDate,
    required this.title,
    required this.quantity,
    required this.remarks,
    required this.revisionFeedback,
    required this.status,
    required this.rawLog,
  });
}
