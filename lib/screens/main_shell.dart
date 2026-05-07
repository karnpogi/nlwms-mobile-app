import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'about_screen.dart';
import 'dashboard.dart';
import 'feedback_screen.dart';
import 'submission_history_screen.dart';
import 'login.dart';
import 'my_duties_screen.dart';
import 'settings_screen.dart';
import 'weekly_ar_screen.dart';

import '../services/api_client.dart';
import '../services/task_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final ApiClient _apiClient;
  late final TaskService _taskService;

  int _selectedIndex = 0;
  bool _loggingOut = false;

  Map<String, dynamic>? _user;
  late final List<_ShellMenuItem> _items;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(baseUrl: 'http://10.0.2.2:8000/api');
    _taskService = TaskService(apiClient: _apiClient);

    _items = [
      _ShellMenuItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        screenBuilder: () => DashboardScreen(taskService: _taskService),
      ),
      _ShellMenuItem(
        title: 'My Duties',
        icon: Icons.assignment_outlined,
        screenBuilder: () => const MyDutiesScreen(),
      ),
      _ShellMenuItem(
        title: 'Submission History',
        icon: Icons.history_outlined,
        screenBuilder: () => SubmissionHistoryScreen(
          taskService: _taskService,
        ),
      ),
      _ShellMenuItem(
        title: 'Feedback',
        icon: Icons.feedback_outlined,
        screenBuilder: () => FeedbackScreen(
          taskService: _taskService,
        ),
      ),
      _ShellMenuItem(
        title: 'Weekly AR',
        icon: Icons.assignment_turned_in_outlined,
        screenBuilder: () => WeeklyARScreen(
          taskService: _taskService,
        ),
      ),
      _ShellMenuItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        screenBuilder: () => SettingsScreen(apiClient: _apiClient),
      ),
      _ShellMenuItem(
        title: 'About',
        icon: Icons.info_outline,
        screenBuilder: () => const AboutScreen(),
      ),
    ];

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('auth_user');

      if (stored == null || stored.trim().isEmpty) return;

      final decoded = jsonDecode(stored);

      if (decoded is Map) {
        final user = decoded.cast<String, dynamic>();

        if (!mounted) return;
        setState(() => _user = user);
      }
    } catch (_) {
      // Keep safe fallback UI.
    }
  }

  String _resolveName() {
    if (_user == null) return 'Library Staff';

    final fullName = _user!['name']?.toString().trim() ?? '';
    final firstName = _user!['first_name']?.toString().trim() ?? '';
    final lastName = _user!['last_name']?.toString().trim() ?? '';

    if (fullName.isNotEmpty) return fullName;

    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;

    return 'Library Staff';
  }

  String _resolveRole() {
    if (_user == null) return 'Library Staff';

    final role = _user!['role']?.toString().trim() ??
        _user!['user_role']?.toString().trim() ??
        '';

    return role.isNotEmpty ? role : 'Library Staff';
  }

  String _resolveSection() {
    if (_user == null) return 'Assigned Section';

    final sectionValue = _user!['section'];
    String section = '';

    if (sectionValue is Map) {
      section = sectionValue['name']?.toString().trim() ?? '';
    } else if (sectionValue != null) {
      section = sectionValue.toString().trim();
    }

    if (section.isEmpty) {
      section = _user!['section_name']?.toString().trim() ??
          _user!['assigned_section']?.toString().trim() ??
          '';
    }

    return section.isNotEmpty ? section : 'Assigned Section';
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'LS';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _resolveAvatarUrl() {
    if (_user == null) return '';

    final avatarUrl = _user!['avatar_url']?.toString().trim() ?? '';
    if (avatarUrl.isNotEmpty) return avatarUrl;

    final avatar = _user!['avatar']?.toString().trim() ?? '';
    return avatar;
  }

  void _showAvatarPreview() {
    final avatarUrl = _resolveAvatarUrl();
    final displayName = _resolveName();
    final initials = _initialsFromName(displayName);

    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 82,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  foregroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          initials,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profile Picture Preview',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar({double radius = 30}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayName = _resolveName();
    final initials = _initialsFromName(displayName);
    final avatarUrl = _resolveAvatarUrl();

    return InkWell(
      onTap: _showAvatarPreview,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: cs.primary.withOpacity(0.12),
        foregroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              )
            : null,
      ),
    );
  }

  void _selectIndex(int index) {
    Navigator.of(context).pop();
    setState(() => _selectedIndex = index);
  }

  Future<void> _clearLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();

    // Current keys used by the mobile app.
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    // Safety cleanup for older/alternate keys that may have been used before.
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('user_data');
    await prefs.remove('current_user');
    await prefs.remove('access_token');
    await prefs.remove('bearer_token');
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    // Close the drawer first so the confirmation dialog appears cleanly.
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      try {
        await _apiClient.post('/mobile/logout', {});
      } catch (_) {
        // Continue local logout even if API logout fails.
      }

      await _clearLocalAuth();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final displayName = _resolveName();
    final displayRole = _resolveRole();
    final displaySection = _resolveSection();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.6,
        ),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(0.25),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(radius: 30),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayRole,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displaySection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_library_outlined,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NLAMS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NEU Library Accomplishment Monitoring System',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required _ShellMenuItem item,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? cs.primary.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            item.icon,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(
            item.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.primary : null,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: _loggingOut
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.error,
                  ),
                )
              : Icon(Icons.logout, color: cs.error),
          title: Text(
            'Logout',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: _loggingOut ? null : _logout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.title),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final selected = index == _selectedIndex;

                    return _buildDrawerItem(
                      context,
                      item: item,
                      selected: selected,
                      onTap: () => _selectIndex(index),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              _buildLogoutTile(context),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: currentItem.screenBuilder(),
      ),
    );
  }
}

class _ShellMenuItem {
  final String title;
  final IconData icon;
  final Widget Function() screenBuilder;

  _ShellMenuItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
  });
}