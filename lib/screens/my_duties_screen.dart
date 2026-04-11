import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_accomplishment_screen.dart';

class MyDutiesScreen extends StatefulWidget {
  const MyDutiesScreen({super.key});

  @override
  State<MyDutiesScreen> createState() => _MyDutiesScreenState();
}

class _MyDutiesScreenState extends State<MyDutiesScreen> {
  bool _loadingUser = true;

  String _userRole = 'Library Staff';
  String _userSection = 'Assigned Section';

  final List<DutyItem> _duties = const [
    DutyItem(
      title: 'Shelving Books',
      description: 'Return books to proper shelves after borrowing/use',
      targetLabel: 'Target: 50 books/day',
      frequency: DutyFrequency.daily,
      proofRequired: false,
    ),
    DutyItem(
      title: 'Research Assistance',
      description: 'Help students and faculty with research queries',
      targetLabel: 'Target: 10 queries/day',
      frequency: DutyFrequency.daily,
      proofRequired: false,
    ),
    DutyItem(
      title: 'Utilization Counting',
      description: 'Count daily library visitors and internet users',
      targetLabel: 'Unit: visitors',
      frequency: DutyFrequency.daily,
      proofRequired: true,
    ),
    DutyItem(
      title: 'Weekly Report Compilation',
      description: 'Compile and submit weekly accomplishment report',
      targetLabel: 'Target: 1 report/week',
      frequency: DutyFrequency.weekly,
      proofRequired: true,
    ),
    DutyItem(
      title: 'Section Inventory Check',
      description: 'Check book inventory of assigned section shelves',
      targetLabel: 'Target: 1 check/month',
      frequency: DutyFrequency.monthly,
      proofRequired: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString('auth_user');

      if (rawUser != null && rawUser.isNotEmpty) {
        final decoded = jsonDecode(rawUser);

        if (decoded is Map<String, dynamic>) {
          final role = decoded['role']?.toString().trim() ??
              decoded['user_role']?.toString().trim() ??
              'Library Staff';

          final section = decoded['section']?.toString().trim() ??
              decoded['section_name']?.toString().trim() ??
              decoded['assigned_section']?.toString().trim() ??
              'Assigned Section';

          if (!mounted) return;

          setState(() {
            _userRole = role.isNotEmpty ? role : 'Library Staff';
            _userSection = section.isNotEmpty ? section : 'Assigned Section';
          });
        }
      }
    } catch (_) {
      // Keep fallback values.
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  Future<void> _refreshPage() async {
    await _loadUserInfo();
  }

  List<DutyItem> get _dailyDuties =>
      _duties.where((d) => d.frequency == DutyFrequency.daily).toList();

  List<DutyItem> get _weeklyDuties =>
      _duties.where((d) => d.frequency == DutyFrequency.weekly).toList();

  List<DutyItem> get _monthlyDuties =>
      _duties.where((d) => d.frequency == DutyFrequency.monthly).toList();

  String _frequencyLabel(DutyFrequency frequency) {
    switch (frequency) {
      case DutyFrequency.daily:
        return 'Daily';
      case DutyFrequency.weekly:
        return 'Weekly';
      case DutyFrequency.monthly:
        return 'Monthly';
    }
  }

  Color _frequencyColor(BuildContext context, DutyFrequency frequency) {
    final cs = Theme.of(context).colorScheme;

    switch (frequency) {
      case DutyFrequency.daily:
        return cs.primary;
      case DutyFrequency.weekly:
        return Colors.deepPurple;
      case DutyFrequency.monthly:
        return Colors.orange;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Duties',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your role and section assignment',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: _loadingUser
              ? Text(
                  'Loading assignment details...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userRole,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userSection,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _openLogScreen(BuildContext context, DutyItem duty) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogAccomplishmentScreen(
          duty: {
            'title': duty.title,
            'frequency': _frequencyLabel(duty.frequency),
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDutyCard(BuildContext context, DutyItem duty) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final frequencyColor = _frequencyColor(context, duty.frequency);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openLogScreen(context, duty),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      duty.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    context,
                    label: _frequencyLabel(duty.frequency),
                    textColor: frequencyColor,
                    backgroundColor: frequencyColor.withOpacity(0.10),
                    borderColor: frequencyColor.withOpacity(0.25),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                duty.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    context,
                    label: duty.targetLabel,
                    icon: Icons.flag_outlined,
                  ),
                  if (duty.proofRequired)
                    _buildBadge(
                      context,
                      label: 'Proof Required',
                      textColor: Colors.lightBlue,
                      backgroundColor: Colors.lightBlue.withOpacity(0.10),
                      borderColor: Colors.lightBlue.withOpacity(0.25),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required IconData icon,
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

  Widget _buildDutySection(
    BuildContext context, {
    required String title,
    required List<DutyItem> duties,
  }) {
    if (duties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title),
        ...duties.map(
          (duty) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDutyCard(context, duty),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildDutySection(
                  context,
                  title: 'Daily Duties',
                  duties: _dailyDuties,
                ),
                const SizedBox(height: 8),
                _buildDutySection(
                  context,
                  title: 'Weekly Duties',
                  duties: _weeklyDuties,
                ),
                const SizedBox(height: 8),
                _buildDutySection(
                  context,
                  title: 'Monthly Duties',
                  duties: _monthlyDuties,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DutyFrequency {
  daily,
  weekly,
  monthly,
}

class DutyItem {
  final String title;
  final String description;
  final String targetLabel;
  final DutyFrequency frequency;
  final bool proofRequired;

  const DutyItem({
    required this.title,
    required this.description,
    required this.targetLabel,
    required this.frequency,
    required this.proofRequired,
  });
}