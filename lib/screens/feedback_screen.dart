import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/task_service.dart';
import 'submission_history_screen.dart';

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
      final historyResponse = await _taskService.apiClient.get(
        '/mobile/weekly-report/history',
      );

      dynamic decodedHistory;
      try {
        decodedHistory = jsonDecode(historyResponse.body);
      } catch (_) {
        decodedHistory = null;
      }

      if (historyResponse.statusCode != 200 ||
          decodedHistory is! Map<String, dynamic>) {
        throw Exception('Failed to load returned feedback.');
      }

      final rawSubmissions = decodedHistory['data'];
      final submissions = <Map<String, dynamic>>[];

      if (rawSubmissions is List) {
        for (final item in rawSubmissions) {
          if (item is Map) {
            submissions.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final returnedItems = <_ReturnedFeedbackItem>[];

      for (final submission in submissions) {
        final status = submission['status']?.toString().toLowerCase() ?? '';

        if (status != 'returned') continue;

        final submissionId = submission['id'];
        if (submissionId == null) continue;

        final detailResponse = await _taskService.apiClient.get(
          '/mobile/weekly-report/history/$submissionId',
        );

        dynamic decodedDetail;
        try {
          decodedDetail = jsonDecode(detailResponse.body);
        } catch (_) {
          decodedDetail = null;
        }

        if (detailResponse.statusCode != 200 ||
            decodedDetail is! Map<String, dynamic>) {
          continue;
        }

        final data = decodedDetail['data'];
        if (data is! Map) continue;

        final submissionData = data['submission'] is Map
            ? Map<String, dynamic>.from(data['submission'])
            : submission;

        final days = data['days'];
        if (days is! List) continue;

        for (final day in days) {
          if (day is! Map) continue;

          final dayMap = Map<String, dynamic>.from(day);
          final logs = dayMap['logs'];
          if (logs is! List) continue;

          for (final rawLog in logs) {
            if (rawLog is! Map) continue;

            final log = Map<String, dynamic>.from(rawLog);
            final logStatus = log['status']?.toString().toLowerCase() ?? '';
            final requiresRevision = log['requires_revision'] == true ||
                log['requires_revision']?.toString() == '1';
            final revisionFeedback =
                log['revision_feedback']?.toString().trim() ?? '';

            final shouldShow = logStatus == 'returned' ||
                requiresRevision ||
                revisionFeedback.isNotEmpty;

            if (!shouldShow) continue;

            returnedItems.add(
              _ReturnedFeedbackItem(
                logId: _toIntOrNull(log['id']),
                submissionId: submissionId,
                weekStart: submissionData['week_start']?.toString(),
                weekEnd: submissionData['week_end']?.toString(),
                dayLabel: dayMap['day_label']?.toString(),
                activityDate: log['activity_date']?.toString(),
                title: log['duty_template'] is Map
                    ? (log['duty_template']['title']?.toString() ??
                        'Untitled duty')
                    : 'Untitled duty',
                quantity: log['quantity']?.toString() ?? '0',
                remarks: log['remarks']?.toString().trim() ?? '',
                revisionFeedback: revisionFeedback.isNotEmpty
                    ? revisionFeedback
                    : 'This accomplishment log was returned for revision.',
                status: logStatus.isNotEmpty ? logStatus : 'returned',
              ),
            );
          }
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
        builder: (_) => SubmissionHistoryDetailScreen(
          taskService: _taskService,
          submissionId: item.submissionId,
        ),
      ),
    );
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
                  'Returned Feedback',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These are accomplishment logs that were returned by your Unit Head for correction.',
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
                label: const Text('View Submission Details'),
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
        title: const Text('Feedback'),
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
                    'Returned Feedback',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review the specific accomplishment logs returned for revision.',
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
  });
}
