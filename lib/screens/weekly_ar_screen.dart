import 'package:flutter/material.dart';

class WeeklyARScreen extends StatefulWidget {
  const WeeklyARScreen({super.key});

  @override
  State<WeeklyARScreen> createState() => _WeeklyARScreenState();
}

class _WeeklyARScreenState extends State<WeeklyARScreen> {
  bool _isSubmitting = false;

  final List<WeeklyAREntry> _entries = const [
    WeeklyAREntry(
      title: 'Shelving Books',
      dateLabel: 'March 14',
      outputValue: '52',
      outputUnit: 'books',
      hasProof: false,
    ),
    WeeklyAREntry(
      title: 'Monitoring Borrowed Books',
      dateLabel: 'March 14',
      outputValue: '35',
      outputUnit: 'transactions',
      hasProof: false,
    ),
    WeeklyAREntry(
      title: 'Utilization Counting',
      dateLabel: 'March 13',
      outputValue: '145',
      outputUnit: 'visitors',
      hasProof: true,
    ),
    WeeklyAREntry(
      title: 'Research Assistance',
      dateLabel: 'March 13',
      outputValue: '8',
      outputUnit: 'queries',
      hasProof: false,
    ),
    WeeklyAREntry(
      title: 'Shelving Books',
      dateLabel: 'March 12',
      outputValue: '48',
      outputUnit: 'books',
      hasProof: false,
    ),
    WeeklyAREntry(
      title: 'Monitoring Borrowed Books',
      dateLabel: 'March 12',
      outputValue: '42',
      outputUnit: 'transactions',
      hasProof: false,
    ),
  ];

  int get _totalEntries => _entries.length;

  int get _totalOutput {
    int total = 0;
    for (final entry in _entries) {
      total += int.tryParse(entry.outputValue) ?? 0;
    }
    return total;
  }

  Future<void> _submitWeeklyAR() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly accomplishment report submitted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit weekly report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surfaceCard = cs.surface;
    final mutedCard = cs.surfaceVariant.withOpacity(isDark ? 0.25 : 0.45);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly AR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Accomplishment Report',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Compile and submit your weekly accomplishment entries',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(
                              isDark ? 0.10 : 0.05,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: mutedCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporting Week',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'March 10 - March 14, 2026',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(
                              isDark ? 0.10 : 0.05,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryStat(
                                  label: 'Total Entries',
                                  value: _totalEntries.toString(),
                                  alignment: CrossAxisAlignment.start,
                                ),
                              ),
                              Expanded(
                                child: _SummaryStat(
                                  label: 'Total Output',
                                  value: _totalOutput.toString(),
                                  alignment: CrossAxisAlignment.end,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  'Draft',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
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
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Review your entries below, then submit for Unit Head review.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Review flow: You → Unit Head → Head Librarian',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ..._entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WeeklyEntryCard(entry: entry),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitWeeklyAR,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Weekly AR'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.alignment,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: textAlign,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WeeklyEntryCard extends StatelessWidget {
  final WeeklyAREntry entry;

  const _WeeklyEntryCard({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      entry.dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (entry.hasProof) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Proof',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: entry.outputValue,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' ${entry.outputUnit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeeklyAREntry {
  final String title;
  final String dateLabel;
  final String outputValue;
  final String outputUnit;
  final bool hasProof;

  const WeeklyAREntry({
    required this.title,
    required this.dateLabel,
    required this.outputValue,
    required this.outputUnit,
    this.hasProof = false,
  });
}