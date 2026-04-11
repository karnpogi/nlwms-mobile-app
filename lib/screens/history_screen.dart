import 'package:flutter/material.dart';

import '../models/accomplishment_log_item.dart';
import 'log_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  bool _loading = false;
  String? _error;

  final List<AccomplishmentLogItem> _logs = [
    AccomplishmentLogItem(
      id: 1,
      dutyTitle: 'Shelving Books',
      remarks: 'Returned and arranged borrowed books to their correct shelves.',
      activityDate: DateTime(2026, 4, 8),
      quantity: 48,
      status: 'draft',
      feedbackEntries: [],
    ),
    AccomplishmentLogItem(
      id: 2,
      dutyTitle: 'Research Assistance',
      remarks: 'Assisted students with thesis-related references.',
      activityDate: DateTime(2026, 4, 7),
      quantity: 9,
      status: 'under_review',
      feedbackEntries: [
        FeedbackEntry(
          id: 2001,
          userName: 'Unit Head',
          text: 'Please add more specific details about the assistance provided.',
          createdAt: DateTime(2026, 4, 7, 10, 30),
        ),
      ],
    ),
    AccomplishmentLogItem(
      id: 3,
      dutyTitle: 'Utilization Counting',
      remarks: 'Counted library visitors and internet users for the day.',
      activityDate: DateTime(2026, 4, 6),
      quantity: 126,
      status: 'verified',
      feedbackEntries: [
        FeedbackEntry(
          id: 3001,
          userName: 'Unit Head',
          text: 'Verified and accepted.',
          createdAt: DateTime(2026, 4, 6, 16, 15),
        ),
      ],
    ),
    AccomplishmentLogItem(
      id: 4,
      dutyTitle: 'Weekly Report Compilation',
      remarks: 'Prepared accomplishment summary for weekly submission.',
      activityDate: DateTime(2026, 4, 5),
      quantity: 1,
      status: 'submitted',
      feedbackEntries: [],
    ),
    AccomplishmentLogItem(
      id: 5,
      dutyTitle: 'Section Inventory Check',
      remarks: 'Some item counts need correction based on actual shelf review.',
      activityDate: DateTime(2026, 4, 3),
      quantity: 1,
      status: 'needs_revision',
      feedbackEntries: [
        FeedbackEntry(
          id: 5001,
          userName: 'Unit Head',
          text: 'Please recheck the actual shelf count and update the quantity.',
          createdAt: DateTime(2026, 4, 3, 14, 20),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      final value = _searchCtrl.text.trim().toLowerCase();
      setState(() => _searchQuery = value);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 700));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int get _draftCount => _logs.where((log) => log.status == 'draft').length;

  int get _underReviewCount =>
      _logs.where((log) => log.status == 'under_review').length;

  int get _verifiedCount =>
      _logs.where((log) => log.status == 'verified').length;

  bool _matchesFilter(AccomplishmentLogItem log) {
    switch (_selectedFilter) {
      case 'Draft':
        return log.status == 'draft';
      case 'Submitted':
        return log.status == 'submitted';
      case 'Under Review':
        return log.status == 'under_review';
      case 'Verified':
        return log.status == 'verified';
      case 'Needs Revision':
        return log.status == 'needs_revision';
      case 'All':
      default:
        return true;
    }
  }

  bool _matchesSearch(AccomplishmentLogItem log) {
    if (_searchQuery.isEmpty) return true;

    final dutyTitle = log.dutyTitle.toLowerCase();
    final remarks = log.remarks.toLowerCase();

    return dutyTitle.contains(_searchQuery) || remarks.contains(_searchQuery);
  }

  List<AccomplishmentLogItem> get _filteredLogs {
    return _logs.where((log) => _matchesFilter(log) && _matchesSearch(log)).toList();
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

  Color _statusColor(ColorScheme cs, String status) {
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _filterColor(ColorScheme cs, String filter) {
    switch (filter) {
      case 'Draft':
        return cs.outline;
      case 'Submitted':
        return cs.primary;
      case 'Under Review':
        return Colors.orange;
      case 'Verified':
        return Colors.green;
      case 'Needs Revision':
        return Colors.redAccent;
      case 'All':
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLogs,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Draft',
                      count: _draftCount,
                      icon: Icons.edit_note_outlined,
                      color: cs.outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Under Review',
                      count: _underReviewCount,
                      icon: Icons.hourglass_top_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Verified',
                      count: _verifiedCount,
                      icon: Icons.verified_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => _searchCtrl.clear(),
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: cs.surfaceVariant.withOpacity(
                    theme.brightness == Brightness.dark ? 0.25 : 0.60,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: cs.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedFilter == 'All',
                      color: _filterColor(cs, 'All'),
                      onTap: () => setState(() => _selectedFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Draft',
                      selected: _selectedFilter == 'Draft',
                      color: _filterColor(cs, 'Draft'),
                      onTap: () => setState(() => _selectedFilter = 'Draft'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Submitted',
                      selected: _selectedFilter == 'Submitted',
                      color: _filterColor(cs, 'Submitted'),
                      onTap: () => setState(() => _selectedFilter = 'Submitted'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Under Review',
                      selected: _selectedFilter == 'Under Review',
                      color: _filterColor(cs, 'Under Review'),
                      onTap: () => setState(() => _selectedFilter = 'Under Review'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Verified',
                      selected: _selectedFilter == 'Verified',
                      color: _filterColor(cs, 'Verified'),
                      onTap: () => setState(() => _selectedFilter = 'Verified'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Needs Revision',
                      selected: _selectedFilter == 'Needs Revision',
                      color: _filterColor(cs, 'Needs Revision'),
                      onTap: () =>
                          setState(() => _selectedFilter = 'Needs Revision'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.redAccent),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : _filteredLogs.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.history_toggle_off_rounded,
                                          size: 44,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No history found',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _searchQuery.isEmpty
                                              ? 'Try switching filters.'
                                              : 'Try a different keyword.',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                itemCount: _filteredLogs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final log = _filteredLogs[index];

                                  return _HistoryCard(
                                    log: log,
                                    statusLabel: _statusLabel(log.status),
                                    statusColor: _statusColor(cs, log.status),
                                    dateLabel: _formatDate(log.activityDate),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LogDetailScreen(log: log),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AccomplishmentLogItem log;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.log,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(
                  theme.brightness == Brightness.dark ? 0.10 : 0.06,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      log.dutyTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.remarks,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    icon: Icons.calendar_today_outlined,
                    label: dateLabel,
                  ),
                  _MiniBadge(
                    icon: Icons.numbers_outlined,
                    label: 'Qty: ${log.quantity}',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withOpacity(0.25),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.10 : 0.06,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  count.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.16) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.35)
                : cs.outlineVariant.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? color : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}