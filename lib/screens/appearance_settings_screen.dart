import 'package:flutter/material.dart';
import '../main.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController.themeMode,
        builder: (_, mode, __) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Theme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how NLWMS appears on this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              _ThemeOption(
                title: 'System',
                subtitle: 'Follow device settings',
                selected: mode == ThemeMode.system,
                onTap: () => themeController.setTheme(ThemeMode.system),
              ),
              _ThemeOption(
                title: 'Light',
                subtitle: 'Always use light theme',
                selected: mode == ThemeMode.light,
                onTap: () => themeController.setTheme(ThemeMode.light),
              ),
              _ThemeOption(
                title: 'Dark',
                subtitle: 'Always use dark theme',
                selected: mode == ThemeMode.dark,
                onTap: () => themeController.setTheme(ThemeMode.dark),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(
                    theme.brightness == Brightness.dark ? 0.35 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  'Current theme: ${_modeLabel(mode)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(
        theme.brightness == Brightness.dark ? 0.35 : 0.6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.25),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: cs.primary)
            : Icon(Icons.circle_outlined, color: cs.onSurfaceVariant),
      ),
    );
  }
}