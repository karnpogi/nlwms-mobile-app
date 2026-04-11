import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import 'login.dart';

class MobileChangePasswordScreen extends StatefulWidget {
  final ApiClient apiClient;

  const MobileChangePasswordScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<MobileChangePasswordScreen> createState() =>
      _MobileChangePasswordScreenState();
}

class _MobileChangePasswordScreenState
    extends State<MobileChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _show = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _messageFromBody(dynamic body, {String fallback = 'Request failed.'}) {
    if (body is Map<String, dynamic>) {
      final msg = body['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;

      final errors = body['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String && v.isNotEmpty) return v;
        }
      }
    }
    return fallback;
  }

  Future<void> _forceLogout() async {
    try {
      await widget.apiClient.post('/auth/logout', {});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final res = await widget.apiClient.put('/auth/change-password', {
        'current_password': _current.text.trim(),
        'password': _newPass.text,
        'password_confirmation': _confirm.text,
      });

      dynamic body;
      if (res.body.isNotEmpty) {
        try {
          body = jsonDecode(res.body);
        } catch (_) {
          body = res.body;
        }
      }

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final msg = _messageFromBody(
          body,
          fallback: 'Password updated successfully.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );

        await _forceLogout();
        return;
      }

      final msg = _messageFromBody(
        body,
        fallback: 'Failed (code: ${res.statusCode}).',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(
        theme.brightness == Brightness.dark ? 0.35 : 0.6,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Update your password",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For your security, you will be logged out after changing your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _current,
                  obscureText: !_show,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Current Password',
                    icon: Icons.lock_outline,
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPass,
                  obscureText: !_show,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'New Password',
                    icon: Icons.password,
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'New password is required';
                    if (s.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: !_show,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Confirm New Password',
                    icon: Icons.password_outlined,
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (v != _newPass.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Switch(
                        value: _show,
                        onChanged: (v) => setState(() => _show = v),
                      ),
                      Expanded(
                        child: Text(
                          _show ? 'Show passwords' : 'Hide passwords',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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