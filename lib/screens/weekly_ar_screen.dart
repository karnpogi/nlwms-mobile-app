import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import 'log_accomplishment_screen.dart';
import 'submission_history_screen.dart';

class WeeklyARScreen extends StatefulWidget {
  final TaskService taskService;

  const WeeklyARScreen({
    super.key,
    required this.taskService,
  });

  @override
  State<WeeklyARScreen> createState() => _WeeklyARScreenState();
}

class _WeeklyARScreenState extends State<WeeklyARScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _submissionStatus = 'Draft';
  String _submissionStatusText = 'Not yet submitted';
  String _reportingWeekLabel = '';
  String? _submissionFeedback;

  List<Map<String, dynamic>> _days = [];

  DateTime get _today => DateTime.now();

  DateTime get _weekStart {
    final now = _today;
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 4));

  bool get _isReturned => _submissionStatus.toLowerCase() == 'returned';

  bool get _canSubmit {
    final status = _submissionStatus.toLowerCase();
    return status == 'draft' || status == 'returned';
  }

  bool _canEditLog(Map<String, dynamic> log) {
    final logStatus = log['status']?.toString().toLowerCase();
    final requiresRevision = log['requires_revision'] == true ||
        log['requires_revision']?.toString() == '1';

    return _isReturned && (logStatus == 'returned' || requiresRevision);
  }

  String _formatDate(DateTime date) {
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

  String _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return 'Draft';

    final clean = status.trim().toLowerCase();
    return clean[0].toUpperCase() + clean.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyReport();
  }

  Future<void> _loadWeeklyReport() async {
    setState(() => _isLoading = true);

    try {
      final response = await widget.taskService.apiClient.get(
        '/mobile/weekly-report',
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final weekStart = decoded['week_start']?.toString();
        final weekEnd = decoded['week_end']?.toString();
        final submission = decoded['submission'];
        final rawDays = decoded['days'];

        String reportingWeek = '';
        if (weekStart != null && weekEnd != null) {
          final start = DateTime.tryParse(weekStart);
          final end = DateTime.tryParse(weekEnd);
          if (start != null && end != null) {
            reportingWeek = '${_formatDate(start)} - ${_formatDate(end)}';
          }
        }

        String status = 'Draft';
        String statusText = 'Not yet submitted';
        String? feedback;

        if (submission is Map<String, dynamic>) {
          final rawStatus = submission['status']?.toString().trim();
          status = _normalizeStatus(rawStatus);
          feedback = submission['feedback']?.toString();

          switch (rawStatus?.toLowerCase()) {
            case 'submitted':
              statusText = 'Submitted for Unit Head review';
              break;
            case 'reviewed':
              statusText = 'Reviewed by Unit Head';
              break;
            case 'returned':
              statusText = 'Returned for revision';
              break;
            case 'verified':
              statusText = 'Verified by Head Librarian';
              break;
            default:
              statusText = 'Not yet submitted';
          }
        }

        final days = <Map<String, dynamic>>[];
        if (rawDays is List) {
          for (final item in rawDays) {
            if (item is Map<String, dynamic>) {
              days.add(item);
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _reportingWeekLabel = reportingWeek;
          _submissionStatus = status;
          _submissionStatusText = statusText;
          _submissionFeedback = feedback;
          _days = days;
        });
      } else {
        throw Exception('Failed to load weekly report: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load weekly report: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitWeeklyAR() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await widget.taskService.apiClient.post(
        '/mobile/submissions',
        {
          'week_start': _weekStart.toIso8601String().split('T').first,
          'week_end': _weekEnd.toIso8601String().split('T').first,
        },
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        final message =
            decoded is Map<String, dynamic> && decoded['message'] != null
                ? decoded['message'].toString()
                : 'Weekly accomplishment report submitted successfully.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        await _loadWeeklyReport();
        return;
      }

      String errorMessage = 'Submission failed';

      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        } else if (decoded['errors'] is Map && decoded['errors'].isNotEmpty) {
          final firstError = decoded['errors'].values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else {
            errorMessage = firstError.toString();
          }
        }
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit weekly report: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openNewLogAccomplishment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LogAccomplishmentScreen(),
      ),
    );

    if (!mounted) return;
    await _loadWeeklyReport();
  }

  Future<void> _openEditLog(Map<String, dynamic> log) async {
    if (!_canEditLog(log)) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogAccomplishmentScreen(
          existingLog: log,
        ),
      ),
    );

    if (!mounted) return;
    await _loadWeeklyReport();
  }

  Widget _buildFeedbackCard() {
    // General Weekly AR feedback is intentionally hidden on mobile.
    // Staff-facing correction notes are shown inside each specific returned log card.
    return const SizedBox.shrink();
  }

  Widget _buildRevisionActionCard() {
    if (!_isReturned) return const SizedBox.shrink();

    return Card(
      color: Colors.blueGrey.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revision Action',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Only accomplishment logs specifically returned by the Unit Head can be edited. Other logs are view-only.',
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
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
                fontWeight: FontWeight.w700,
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
                final item = Map<String, dynamic>.from(log as Map);
                final title = item['duty_template']?['title']?.toString() ??
                    'Untitled duty';
                final quantity = item['quantity']?.toString() ?? '0';
                final remarks = item['remarks']?.toString() ?? '';
                final revisionFeedback =
                    item['revision_feedback']?.toString().trim() ?? '';
                final canEditThisLog = _canEditLog(item);

                return InkWell(
                  onTap: canEditThisLog ? () => _openEditLog(item) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: canEditThisLog
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: canEditThisLog
                            ? Colors.orange.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canEditThisLog) ...[
                          Icon(
                            Icons.edit_note_outlined,
                            size: 20,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Revision Note',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w700,
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
                              if (canEditThisLog) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to edit',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (!_canSubmit) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitWeeklyAR,
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isReturned ? 'Resubmit Weekly AR' : 'Submit Weekly AR'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly AR'),
        actions: [
          IconButton(
            tooltip: 'Submission History',
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmissionHistoryScreen(
                    taskService: widget.taskService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeeklyReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Weekly Accomplishment Report',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compile and submit your weekly accomplishment entries',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmissionHistoryScreen(
                              taskService: widget.taskService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history_outlined),
                      label: const Text('View Submission History'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reporting Week',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _reportingWeekLabel.isEmpty
                                      ? '${_formatDate(_weekStart)} - ${_formatDate(_weekEnd)}'
                                      : _reportingWeekLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(_submissionStatus),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Details',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _submissionStatusText,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackCard(),
                  if (_isReturned) const SizedBox(height: 12),
                  _buildRevisionActionCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'Review flow: You → Unit Head → Head Librarian',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ..._days.map(_buildDayCard),
                  const SizedBox(height: 8),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }
}