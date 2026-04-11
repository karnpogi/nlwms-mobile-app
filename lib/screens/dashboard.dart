import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import 'feedback_screen.dart';
import 'log_accomplishment_screen.dart';
import 'my_duties_screen.dart';
import 'weekly_ar_screen.dart';

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

  String _userName = 'Library Staff';
  String _userRole = 'Library Staff';
  String _userSection = 'Assigned Section';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadEntries();
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
          final section = decoded['section']?.toString().trim() ??
              decoded['section_name']?.toString().trim() ??
              decoded['assigned_section']?.toString().trim() ??
              'Assigned Section';

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

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await widget.taskService.getTasks();
      setState(() => _entries = entries);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _loggedThisWeek => _entries.length;
  int get _verifiedCount => _entries.where((e) => e.status == 'done').length;
  int get _underReviewCount =>
      _entries.where((e) => e.status == 'in_progress').length;
  int get _needsRevisionCount =>
      _entries.where((e) => e.status == 'pending').length;

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
    switch (status) {
      case 'done':
        return 'Verified';
      case 'in_progress':
        return 'Under Review';
      case 'pending':
      default:
        return 'Needs Revision';
    }
  }

  Color _feedbackStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.redAccent;
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

  Widget _buildWeeklyReportCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WeeklyARScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: cs.onSurface),
                const SizedBox(width: 8),
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
              'March 16 - March 20, 2026',
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
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Draft',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Not yet submitted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Review and Submit',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              label: 'Logged This Week',
              value: _loggedThisWeek,
              valueColor: Colors.blue,
            ),
            _buildStatCard(
              context: context,
              label: 'Verified',
              value: _verifiedCount,
              valueColor: Colors.green,
            ),
            _buildStatCard(
              context: context,
              label: 'Under Review',
              value: _underReviewCount,
              valueColor: Colors.blueGrey,
            ),
            _buildStatCard(
              context: context,
              label: 'Needs Revision',
              value: _needsRevisionCount,
              valueColor: Colors.orange,
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
              icon: Icons.edit_note_outlined,
              label: 'Log Accomplishment',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LogAccomplishmentScreen(),
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
                    builder: (_) => const WeeklyARScreen(),
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
            _loadEntries(),
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