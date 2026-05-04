import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import 'feedback_screen.dart';
import 'my_duties_screen.dart';
import 'weekly_ar_screen.dart';
import 'submission_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final TaskService taskService;

  const DashboardScreen({
    super.key,
    required this.taskService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = false;
  bool _userLoading = true;
  String? _error;

  List<Task> _entries = [];

  int _totalSubmissions = 0;
  int _submittedCount = 0;
  int _reviewedCount = 0;
  int _returnedCount = 0;
  int _verifiedCount = 0;
  int _totalLogs = 0;
  String _weeklyReportStatus = 'draft';

  String _userName = 'Library Staff';
  String _userRole = 'Library Staff';
  String _userSection = 'Assigned Section';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDashboard();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString('auth_user');

      if (rawUser != null && rawUser.isNotEmpty) {
        final decoded = jsonDecode(rawUser);

        if (decoded is Map<String, dynamic>) {
          final firstName = decoded['first_name']?.toString().trim() ?? '';
          final lastName = decoded['last_name']?.toString().trim() ?? '';
          final fullName = decoded['name']?.toString().trim() ?? '';
          final role = decoded['role']?.toString().trim() ??
              decoded['user_role']?.toString().trim() ??
              'Library Staff';

          String section = 'Assigned Section';
          final sectionValue = decoded['section'];

          if (sectionValue is Map<String, dynamic>) {
            section = sectionValue['name']?.toString().trim() ??
                decoded['section_name']?.toString().trim() ??
                decoded['assigned_section']?.toString().trim() ??
                'Assigned Section';
          } else {
            section = decoded['section']?.toString().trim() ??
                decoded['section_name']?.toString().trim() ??
                decoded['assigned_section']?.toString().trim() ??
                'Assigned Section';
          }

          String resolvedName = 'Library Staff';

          if (fullName.isNotEmpty) {
            resolvedName = fullName;
          } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
            resolvedName = '$firstName $lastName'.trim();
          }

          if (!mounted) return;

          setState(() {
            _userName = resolvedName;
            _userRole = role.isNotEmpty ? role : 'Library Staff';
            _userSection = section.isNotEmpty ? section : 'Assigned Section';
          });
        }
      }
    } catch (_) {
      // Keep safe fallbacks.
    } finally {
      if (mounted) {
        setState(() => _userLoading = false);
      }
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dashboardRes =
          await widget.taskService.apiClient.get('/mobile/dashboard');

      if (dashboardRes.statusCode != 200) {
        throw Exception(
          'Failed to load dashboard: ${dashboardRes.statusCode}',
        );
      }

      final dashboardDecoded = jsonDecode(dashboardRes.body);

      if (dashboardDecoded is! Map<String, dynamic>) {
        throw Exception('Invalid dashboard response.');
      }

      // Logs are fetched only for Recent Feedback display.
      // Dashboard counters now come only from /mobile/dashboard.
      final logsRes = await widget.taskService.apiClient.get('/mobile/logs');

      List<dynamic> logs = [];

      if (logsRes.statusCode == 200) {
        final logsDecoded = jsonDecode(logsRes.body);

        if (logsDecoded is Map<String, dynamic> &&
            logsDecoded['data'] is List) {
          logs = logsDecoded['data'] as List<dynamic>;
        } else if (logsDecoded is List) {
          logs = logsDecoded;
        }
      }

      String weeklyStatus = 'draft';
      try {
        final weeklyRes =
            await widget.taskService.apiClient.get('/mobile/weekly-report');

        if (weeklyRes.statusCode == 200) {
          final weeklyDecoded = jsonDecode(weeklyRes.body);
          weeklyStatus = _extractWeeklyStatus(weeklyDecoded);
        }
      } catch (_) {
        weeklyStatus = 'draft';
      }

      final mappedLogs = logs
          .whereType<Map>()
          .map((e) => _mapLogToTask(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;

      setState(() {
        _totalSubmissions = _toInt(dashboardDecoded['total_submissions']);
        _submittedCount = _toInt(dashboardDecoded['submitted_count']);
        _reviewedCount = _toInt(dashboardDecoded['reviewed_count']);
        _returnedCount = _toInt(dashboardDecoded['returned_count']);
        _verifiedCount = _toInt(dashboardDecoded['verified_count']);
        _totalLogs = _toInt(dashboardDecoded['total_logs']);
        _weeklyReportStatus = weeklyStatus;

        _entries = mappedLogs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Task _mapLogToTask(Map<String, dynamic> log) {
    final activityDate = log['activity_date']?.toString();
    final createdAt = log['created_at']?.toString();

    return Task(
      id: _toInt(log['id']),
      userId: null,
      title: log['duty_title']?.toString() ?? 'Untitled Log',
      description: log['remarks']?.toString(),
      status: log['status']?.toString().toLowerCase() ?? 'draft',
      priority: null,
      coverColor: null,
      dueDate: activityDate != null ? DateTime.tryParse(activityDate) : null,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt) : null,
      updatedAt: null,
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  List<Task> get _recentFeedbackEntries => _entries.take(2).toList();

  String _formatDate(DateTime date) {
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
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _feedbackStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Verified';
      case 'reviewed':
        return 'Reviewed';
      case 'submitted':
        return 'Submitted';
      case 'returned':
        return 'Returned';
      case 'draft':
      default:
        return 'Draft';
    }
  }

  Color _feedbackStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'reviewed':
        return Colors.amber.shade700;
      case 'submitted':
        return Colors.blue;
      case 'returned':
        return Colors.orange;
      case 'draft':
      default:
        return Colors.grey;
    }
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userLoading ? 'Loading...' : _userName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$_userRole • $_userSection',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _extractWeeklyStatus(dynamic decoded) {
    dynamic data = decoded;

    if (decoded is Map<String, dynamic>) {
      data = decoded['data'] ?? decoded['submission'] ?? decoded['weekly_report'] ?? decoded;
    }

    if (data is Map<String, dynamic>) {
      final status = data['status']?.toString().trim().toLowerCase();
      if (status != null && status.isNotEmpty) return status;
    }

    return 'draft';
  }

  String _weeklyStatusLabel() {
    switch (_weeklyReportStatus.toLowerCase()) {
      case 'submitted':
        return 'Submitted AR';
      case 'reviewed':
        return 'Reviewed AR';
      case 'returned':
        return 'Returned AR';
      case 'verified':
        return 'Verified AR';
      case 'draft':
      default:
        return 'Current Week';
    }
  }

  String _weeklyActionLabel() {
    switch (_weeklyReportStatus.toLowerCase()) {
      case 'returned':
        return 'Revise AR';
      case 'submitted':
        return 'Waiting for review';
      case 'reviewed':
        return 'Reviewed by Unit Head';
      case 'verified':
        return 'Verified by Head Librarian';
      case 'draft':
      default:
        return 'Review and submit your AR';
    }
  }

  Color _weeklyBaseColor(BuildContext context) {
    switch (_weeklyReportStatus.toLowerCase()) {
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
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildWeeklyReportCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseColor = _weeklyBaseColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeeklyARScreen(taskService: widget.taskService),
          ),
        ).then((_) => _loadDashboard());
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(isDark ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: baseColor.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: baseColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Weekly Accomplishment Report',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Open your weekly accomplishment report',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: baseColor.withOpacity(0.24)),
                  ),
                  child: Text(
                    _weeklyStatusLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: baseColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _weeklyActionLabel(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: baseColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required int value,
    required Color valueColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, Task entry) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusLabel = _feedbackStatusLabel(entry.status);
    final statusColor = _feedbackStatusColor(entry.status);
    final date = entry.dueDate ?? DateTime.now();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeedbackScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reviewed by Unit Head • ${_formatDate(date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.description?.trim().isNotEmpty == true
                  ? entry.description!
                  : 'No recent feedback yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'View Details',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.error.withOpacity(0.20)),
        ),
        child: Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreetingHeader(context),
        const SizedBox(height: 16),
        _buildWeeklyReportCard(context),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.45,
          children: [
            _buildStatCard(
              context: context,
              label: 'Total Submissions',
              value: _totalSubmissions,
              valueColor: Colors.blue,
            ),
            _buildStatCard(
              context: context,
              label: 'Submitted',
              value: _submittedCount,
              valueColor: Colors.blueAccent,
            ),
            _buildStatCard(
              context: context,
              label: 'Reviewed',
              value: _reviewedCount,
              valueColor: Colors.amber.shade700,
            ),
            _buildStatCard(
              context: context,
              label: 'Returned',
              value: _returnedCount,
              valueColor: Colors.orange,
            ),
            _buildStatCard(
              context: context,
              label: 'Verified',
              value: _verifiedCount,
              valueColor: Colors.green,
            ),
            _buildStatCard(
              context: context,
              label: 'Total Logs',
              value: _totalLogs,
              valueColor: Colors.deepPurple,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSectionTitle(context, 'Quick Actions'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.75,
          children: [
            _buildQuickAction(
              context: context,
              icon: Icons.library_books_outlined,
              label: 'My Duties',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyDutiesScreen(),
                  ),
                );
              },
            ),
            _buildQuickAction(
              context: context,
              icon: Icons.history_outlined,
              label: 'Submission History',
              onTap: () {
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
            _buildQuickAction(
              context: context,
              icon: Icons.assignment_turned_in_outlined,
              label: 'Weekly AR',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyARScreen(
                      taskService: widget.taskService,
                    ),
                  ),
                );
              },
            ),
            _buildQuickAction(
              context: context,
              icon: Icons.feedback_outlined,
              label: 'Feedback',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FeedbackScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSectionTitle(context, 'Recent Feedback'),
        const SizedBox(height: 10),
        if (_recentFeedbackEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: Text(
              'No recent feedback yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            children: _recentFeedbackEntries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildFeedbackCard(context, entry),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadUser(),
            _loadDashboard(),
          ]);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }
}