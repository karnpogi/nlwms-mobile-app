import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool pushNotifications = true;
  bool dutyReminders = true;
  bool weeklyArAlerts = true;
  bool feedbackUpdates = true;
  bool systemAnnouncements = true;
  bool submissionStatusAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Manage Notifications",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which reminders and updates you want to receive in NLAMS.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          _NotificationCard(
            context: context,
            value: pushNotifications,
            onChanged: (value) {
              setState(() => pushNotifications = value);
            },
            title: 'Enable Push Notifications',
            subtitle: 'Turn all app notifications on or off',
          ),

          const SizedBox(height: 12),

          _NotificationCard(
            context: context,
            value: dutyReminders,
            onChanged: pushNotifications
                ? (value) => setState(() => dutyReminders = value)
                : null,
            title: 'Duty Reminders',
            subtitle: 'Receive reminders for assigned duties and logging',
          ),

          _NotificationCard(
            context: context,
            value: weeklyArAlerts,
            onChanged: pushNotifications
                ? (value) => setState(() => weeklyArAlerts = value)
                : null,
            title: 'Weekly AR Alerts',
            subtitle: 'Get reminders for weekly accomplishment reports',
          ),

          _NotificationCard(
            context: context,
            value: feedbackUpdates,
            onChanged: pushNotifications
                ? (value) => setState(() => feedbackUpdates = value)
                : null,
            title: 'Feedback Updates',
            subtitle: 'Be notified when reviewer feedback is available',
          ),

          _NotificationCard(
            context: context,
            value: submissionStatusAlerts,
            onChanged: pushNotifications
                ? (value) =>
                    setState(() => submissionStatusAlerts = value)
                : null,
            title: 'Submission Status Alerts',
            subtitle: 'Know when reports are under review, verified, or returned',
          ),

          _NotificationCard(
            context: context,
            value: systemAnnouncements,
            onChanged: pushNotifications
                ? (value) => setState(() => systemAnnouncements = value)
                : null,
            title: 'System Announcements',
            subtitle: 'Receive notices about app updates and important advisories',
          ),
        ],
      ),
    );
  }

  Widget _NotificationCard({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.6,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeColor: cs.primary,
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
      ),
    );
  }
}