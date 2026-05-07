import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About NLAMS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.local_library_outlined,
                  size: 80,
                  color: cs.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'NLAMS',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'NEU Library Accomplishment Monitoring System',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoCard(
            title: 'What this app does',
            child: Text(
              'NLAMS is a mobile application for authorized New Era University Main Library staff. It helps staff record completed duties, add remarks, enter quantities when needed, attach proof when required, submit weekly accomplishment reports, and review feedback or returned entries from the Unit Head.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Core features',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureLine(text: 'View assigned duties based on job title'),
                _FeatureLine(text: 'Log completed accomplishments'),
                _FeatureLine(text: 'Enter quantity and remarks when needed'),
                _FeatureLine(text: 'Upload proof for duties that require it'),
                _FeatureLine(text: 'Submit weekly accomplishment reports'),
                _FeatureLine(text: 'View returned feedback and resubmit corrections'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'For internal use',
            child: Text(
              'This application is intended for authorized library staff only. It does not replace the actual library work process. Staff still perform their duties in the library, while the app is used to record completed work for review, monitoring, and evaluation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  'Developed for New Era University Main Library',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '© 2026 NLAMS. All rights reserved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.75),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.6,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;

  const _FeatureLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}