import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Reviews'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feedback & Reviews',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review comments and verification from supervisors',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              _ReviewCard(
                title: 'Internet Station Assistance',
                meta: 'Mar 5, 2026 • 2 UI Hours assisted',
                statusLabel: 'Needs Revision',
                statusColor: const Color(0xFFE2B24A),
                statusBg: const Color(0xFFFFF3D6),
                reviewerLine: 'Returned by Unit Head',
                reviewerName: 'Ma. Bella Dea',
                reviewerMeta: 'Unit Head • Mar 5, 2026 • 2:25 AM',
                feedbackText:
                    'Please include the user count breakdown by time slot (morning/afternoon). Also attach the tally log sheet as proof.',
                actionLabel: 'Edit & Resubmit',
                onActionTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Open log for editing and resubmission'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _ReviewCard(
                title: 'Utilization Counting',
                meta: 'Apr 29, 2026 • 143 visitors',
                statusLabel: 'Verified',
                statusColor: const Color(0xFF53B36B),
                statusBg: const Color(0xFFE8F7EC),
                reviewerLine: 'Verified by Unit Head',
                reviewerName: 'Rio Garcia',
                reviewerMeta: 'Unit Head • Apr 29, 2026',
                feedbackText:
                    'Reviewed. Counts are consistent with gate control records.',
              ),

              const SizedBox(height: 14),

              _ReviewCard(
                title: 'Research Assistance',
                meta: 'Apr 29, 2026 • 9 queries',
                statusLabel: 'Verified',
                statusColor: const Color(0xFF53B36B),
                statusBg: const Color(0xFFE8F7EC),
                reviewerLine: 'Verified by Unit Head',
                reviewerName: 'Rio Garcia',
                reviewerMeta: 'Unit Head • Feb 26, 2026',
                feedbackText:
                    'Verified. Keep tagging details of sources for reference tracking.',
              ),

              SizedBox(height: isDark ? 8 : 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final String meta;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String reviewerLine;
  final String reviewerName;
  final String reviewerMeta;
  final String feedbackText;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _ReviewCard({
    required this.title,
    required this.meta,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.reviewerLine,
    required this.reviewerName,
    required this.reviewerMeta,
    required this.feedbackText,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.05),
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 4),
          Text(
            meta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.reply_outlined,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reviewerLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(isDark ? 0.25 : 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.surface,
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reviewerName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reviewerMeta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedbackText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                onPressed: onActionTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}