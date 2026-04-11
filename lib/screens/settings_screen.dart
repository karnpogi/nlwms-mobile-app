import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import 'login.dart';

import 'about_screen.dart';
import 'profile_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const SettingsScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggingOut = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_user');

    if (stored != null) {
      setState(() {
        _user = jsonDecode(stored);
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);

    try {
      await widget.apiClient.post('/auth/logout', {});

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  String _resolveRole(Map<String, dynamic> user) {
    final role = user['role']?.toString().trim() ??
        user['user_role']?.toString().trim() ??
        '';
    return role.isNotEmpty ? role : 'Library Staff';
  }

  String _resolveSection(Map<String, dynamic> user) {
    final section = user['section']?.toString().trim() ??
        user['section_name']?.toString().trim() ??
        user['assigned_section']?.toString().trim() ??
        '';
    return section.isNotEmpty ? section : 'Assigned Section';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_user != null) ...[
            Container(
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cs.primary.withOpacity(0.12),
                    child: Icon(Icons.person, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user!['name']?.toString().trim().isNotEmpty == true
                              ? _user!['name'].toString()
                              : 'Library Staff',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_resolveRole(_user!)} • ${_resolveSection(_user!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if ((_user!['email'] ?? '').toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _user!['email'].toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _SectionTitle(title: "Account"),
          _SettingsTile(
            icon: Icons.person_outline,
            title: "Profile",
            subtitle: "Update profile information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileSettingsScreen(apiClient: widget.apiClient),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            subtitle: "Update your account password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MobileChangePasswordScreen(
                    apiClient: widget.apiClient,
                  ),
                ),
              );
            },
          ),

          _SectionTitle(title: "Preferences"),
          _SettingsTile(
            icon: Icons.color_lens_outlined,
            title: "Appearance",
            subtitle: "Theme and display settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppearanceSettingsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            title: "Notifications",
            subtitle: "Reminders, feedback, and status alerts",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),

          _SectionTitle(title: "About"),
          _SettingsTile(
            icon: Icons.info_outline,
            title: "About NLWMS",
            subtitle: "App version and system information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _loggingOut ? null : _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    "Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
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
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      ),
    );
  }
}