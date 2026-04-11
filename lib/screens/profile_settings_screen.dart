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
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  final _picker = ImagePicker();

  String _avatarUrl = '';
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_user');
    if (stored == null) return;

    final user = jsonDecode(stored) as Map<String, dynamic>;

    setState(() {
      _nameController.text = (user['name'] ?? '').toString();
      _bioController.text = (user['bio'] ?? '').toString();
      _phoneController.text = (user['phone'] ?? '').toString();

      // Backend-backed avatar
      _avatarUrl = (user['avatar_url'] ?? '').toString();
    });
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
      _nameController.text = (user['name'] ?? _nameController.text).toString();
      _bioController.text = (user['bio'] ?? _bioController.text).toString();
      _phoneController.text = (user['phone'] ?? _phoneController.text).toString();
      _avatarUrl = (user['avatar_url'] ?? '').toString();
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
        '/me/avatar',
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
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploadingAvatar = true);

    try {
      final res = await widget.apiClient.deleteAuth('/me/avatar');

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
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              if (_avatarUrl.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Keep your current local-save behavior for profile info (until API exists)
  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('auth_user');

      if (stored != null) {
        final user = (jsonDecode(stored) as Map).cast<String, dynamic>();
        user['name'] = _nameController.text.trim();
        user['bio'] = _bioController.text.trim();
        user['phone'] = _phoneController.text.trim();
        await prefs.setString('auth_user', jsonEncode(user));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fieldFill = cs.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.6,
    );

    final initials = _initialsFromName(_nameController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
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
                        padding: const EdgeInsets.all(8),
                        child: _uploadingAvatar
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Icon(Icons.edit, color: cs.onPrimary, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          TextField(
            controller: _nameController,
            decoration: _input("Display name", fieldFill, cs),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: _input("Bio (optional)", fieldFill, cs),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _input("Phone (optional)", fieldFill, cs),
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, Color fill, ColorScheme cs) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.25)),
      ),
    );
  }
}