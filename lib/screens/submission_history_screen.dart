import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/task_service.dart';

class SubmissionHistoryScreen extends StatefulWidget {
  final TaskService taskService;

  const SubmissionHistoryScreen({
    super.key,
    required this.taskService,
  });

  @override
  State<SubmissionHistoryScreen> createState() => _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.taskService.apiClient.get(
        '/mobile/weekly-report/history',
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
        throw Exception('Failed to load submission history.');
      }

      final rawData = decoded['data'];
      final submissions = <Map<String, dynamic>>[];

      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map) {
            submissions.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;
      setState(() => _submissions = submissions);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _statusLabel(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? 'draft';
    if (status.isEmpty) return 'Draft';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'reviewed':
        return Colors.teal;
      case 'returned':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'draft':
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _openDetails(Map<String, dynamic> submission) async {
    final id = submission['id'];
    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionHistoryDetailScreen(
          taskService: widget.taskService,
          submissionId: id,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> submission) {
    final theme = Theme.of(context);
    final status = _statusLabel(submission['status']);
    final color = _statusColor(status);
    final weekStart = _formatDateText(submission['week_start']?.toString());
    final weekEnd = _formatDateText(submission['week_end']?.toString());
    final logsCount = submission['logs_count']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(submission),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$weekStart - $weekEnd',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$logsCount accomplishment log${logsCount == '1' ? '' : 's'} included',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View Details',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Previous Weekly AR Submissions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review your past submissions, statuses, and included accomplishment logs.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: theme.colorScheme.errorContainer.withOpacity(0.55),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  else if (_submissions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No previous submissions yet.'),
                      ),
                    )
                  else
                    ..._submissions.map(_buildHistoryCard),
                ],
              ),
      ),
    );
  }
}

class SubmissionHistoryDetailScreen extends StatefulWidget {
  final TaskService taskService;
  final dynamic submissionId;

  const SubmissionHistoryDetailScreen({
    super.key,
    required this.taskService,
    required this.submissionId,
  });

  @override
  State<SubmissionHistoryDetailScreen> createState() =>
      _SubmissionHistoryDetailScreenState();
}

class _SubmissionHistoryDetailScreenState
    extends State<SubmissionHistoryDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _submission;
  List<Map<String, dynamic>> _days = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.taskService.apiClient.get(
        '/mobile/weekly-report/history/${widget.submissionId}',
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
        throw Exception('Failed to load submission details.');
      }

      final data = decoded['data'];
      if (data is! Map) {
        throw Exception('Invalid submission details response.');
      }

      final submissionRaw = data['submission'];
      final daysRaw = data['days'];
      final days = <Map<String, dynamic>>[];

      if (daysRaw is List) {
        for (final day in daysRaw) {
          if (day is Map) {
            days.add(Map<String, dynamic>.from(day));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _submission = submissionRaw is Map
            ? Map<String, dynamic>.from(submissionRaw)
            : <String, dynamic>{};
        _days = days;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateText(String? value) {
    if (value == null || value.trim().isEmpty) return '—';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _statusLabel(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? 'draft';
    if (status.isEmpty) return 'Draft';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'reviewed':
        return Colors.teal;
      case 'returned':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'draft':
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final submission = _submission ?? {};
    final status = _statusLabel(submission['status']);
    final color = _statusColor(status);
    final weekStart = _formatDateText(submission['week_start']?.toString());
    final weekEnd = _formatDateText(submission['week_end']?.toString());
    final submittedAt = _formatDateText(submission['submitted_at']?.toString());
    final reviewedAt = _formatDateText(submission['reviewed_at']?.toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$weekStart - $weekEnd',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Submitted: $submittedAt'),
            const SizedBox(height: 4),
            Text('Reviewed: $reviewedAt'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final title = log['duty_template']?['title']?.toString() ?? 'Untitled duty';
    final frequency = log['duty_template']?['frequency']?.toString() ?? '—';
    final quantity = log['quantity']?.toString() ?? '0';
    final remarks = log['remarks']?.toString().trim() ?? '';
    final status = _statusLabel(log['status']);
    final revisionFeedback = log['revision_feedback']?.toString().trim() ?? '';
    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.20)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Frequency: $frequency'),
          const SizedBox(height: 4),
          Text('Qty: $quantity'),
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Remarks: $remarks'),
          ],
          if (revisionFeedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revision Note',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    revisionFeedback,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final dayLabel = day['day_label']?.toString() ?? 'Day';
    final logs = (day['logs'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              const Text(
                'No logged accomplishments',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...logs.map((log) {
                if (log is! Map) return const SizedBox.shrink();
                return _buildLogCard(Map<String, dynamic>.from(log));
              }),
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
        title: const Text('Submission Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Weekly AR Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read-only view of a previous weekly accomplishment report.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: theme.colorScheme.errorContainer.withOpacity(0.55),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  else ...[
                    _buildSummaryCard(),
                    const SizedBox(height: 12),
                    const Text(
                      'Included Accomplishment Logs',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._days.map(_buildDayCard),
                  ],
                ],
              ),
      ),
    );
  }
}
