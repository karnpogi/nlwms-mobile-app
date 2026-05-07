import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ProfileSettingsScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _picker = ImagePicker();

  Map<String, dynamic>? _user;
  String _avatarUrl = '';
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_user');
    if (stored == null) return;

    final decoded = jsonDecode(stored);

    if (decoded is Map) {
      final user = decoded.cast<String, dynamic>();

      setState(() {
        _user = user;
        _avatarUrl = _resolveAvatarUrl(user);
      });
    }
  }

  String _displayName() {
    final name = _user?['name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : 'Library Staff';
  }

  String _displayEmail() {
    final email = _user?['email']?.toString().trim() ?? '';
    return email.isNotEmpty ? email : 'No email available';
  }

  String _resolveRole(Map<String, dynamic>? user) {
    if (user == null) return 'Library Staff';

    final role = user['role']?.toString().trim() ??
        user['user_role']?.toString().trim() ??
        '';

    return role.isNotEmpty ? role : 'Library Staff';
  }

  String _resolveSection(Map<String, dynamic>? user) {
    if (user == null) return 'Assigned Section';

    final sectionValue = user['section'];
    String section = '';

    if (sectionValue is Map) {
      section = sectionValue['name']?.toString().trim() ?? '';
    } else if (sectionValue != null) {
      section = sectionValue.toString().trim();
    }

    if (section.isEmpty) {
      section = user['section_name']?.toString().trim() ??
          user['assigned_section']?.toString().trim() ??
          '';
    }

    return section.isNotEmpty ? section : 'Assigned Section';
  }

  String _resolveAvatarUrl(Map<String, dynamic>? user) {
    if (user == null) return '';

    final avatarUrl = user['avatar_url']?.toString().trim() ?? '';
    if (avatarUrl.isNotEmpty) return avatarUrl;

    return user['avatar']?.toString().trim() ?? '';
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

  void _showAvatarPreview() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = _displayName();
    final initials = _initialsFromName(name);
    final avatarUrl = _avatarUrl.trim();

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
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
                foregroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Profile Photo Preview',
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
      ),
    );
  }

  Future<void> _setAuthUserFromResponse(String body) async {
    final decoded = jsonDecode(body);
    final user = (decoded is Map && decoded['user'] is Map)
        ? (decoded['user'] as Map).cast<String, dynamic>()
        : null;

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user));

    if (!mounted) return;

    setState(() {
      _user = user;
      _avatarUrl = _resolveAvatarUrl(user);
    });
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      final res = await widget.apiClient.postMultipart(
        '/mobile/me/avatar',
        fileField: 'avatar',
        file: File(image.path),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _setAuthUserFromResponse(res.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed (${res.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploadingAvatar = true);

    try {
      final res = await widget.apiClient.deleteAuth('/mobile/me/avatar');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _setAuthUserFromResponse(res.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove failed (${res.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take photo'),
                  subtitle: const Text('Use camera to capture a new photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Select an existing image'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(ImageSource.gallery);
                  },
                ),
                if (_avatarUrl.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove photo'),
                    subtitle: const Text('Use initials instead of a photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeAvatar();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountInfoCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.6,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These details are managed by the administrator.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _infoRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: _displayName(),
          ),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _displayEmail(),
          ),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: _resolveRole(_user),
          ),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.apartment_outlined,
            label: 'Section',
            value: _resolveSection(_user),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final name = _displayName();
    final initials = _initialsFromName(name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Photo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: _showAvatarPreview,
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: cs.primary.withOpacity(0.15),
                        foregroundImage: (_avatarUrl.trim().isNotEmpty)
                            ? NetworkImage(_avatarUrl.trim())
                            : null,
                        child: (_avatarUrl.trim().isEmpty)
                            ? Text(
                                initials,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _uploadingAvatar ? null : _showAvatarOptions,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: _uploadingAvatar
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : Icon(
                                    Icons.edit,
                                    color: cs.onPrimary,
                                    size: 19,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the pencil icon to update your photo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _accountInfoCard(),
        ],
      ),
    );
  }
}