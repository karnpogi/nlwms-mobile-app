import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'log_accomplishment_screen.dart';

class MyDutiesScreen extends StatefulWidget {
  const MyDutiesScreen({super.key});

  @override
  State<MyDutiesScreen> createState() => _MyDutiesScreenState();
}

class _MyDutiesScreenState extends State<MyDutiesScreen> {
  final ApiClient _apiClient = ApiClient(baseUrl: 'http://10.0.2.2:8000/api');

  bool _loadingUser = true;
  bool _loadingDuties = true;

  String _userRole = 'Library Staff';
  String _userSection = 'Assigned Section';
  String? _dutiesError;

  List<DutyItem> _duties = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await Future.wait([
      _loadUserInfo(),
      _loadDuties(),
    ]);
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString('auth_user');

      if (rawUser != null && rawUser.isNotEmpty) {
        final decoded = jsonDecode(rawUser);

        if (decoded is Map<String, dynamic>) {
          final role = decoded['role']?.toString().trim() ??
              decoded['user_role']?.toString().trim() ??
              'Library Staff';

          String section = 'Assigned Section';

          final sectionValue = decoded['section'];
          if (sectionValue is Map<String, dynamic>) {
            section = sectionValue['name']?.toString().trim() ??
                decoded['section_name']?.toString().trim() ??
                decoded['assigned_section']?.toString().trim() ??
                'Assigned Section';
          } else {
            section = decoded['section']?.toString().trim() ??
                decoded['section_name']?.toString().trim() ??
                decoded['assigned_section']?.toString().trim() ??
                'Assigned Section';
          }

          if (!mounted) return;

          setState(() {
            _userRole = role.isNotEmpty ? role : 'Library Staff';
            _userSection = section.isNotEmpty ? section : 'Assigned Section';
          });
        }
      }
    } catch (_) {
      // Keep fallback values.
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  Future<void> _loadDuties() async {
    try {
      if (mounted) {
        setState(() {
          _loadingDuties = true;
          _dutiesError = null;
        });
      }

      final response = await _apiClient.get('/mobile/duties');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            rawList = decoded['data'] as List<dynamic>;
          } else if (decoded['duties'] is List) {
            rawList = decoded['duties'] as List<dynamic>;
          }
        }

        final mappedDuties = rawList
            .whereType<Map>()
            .map((item) => _mapDutyItem(Map<String, dynamic>.from(item)))
            .toList();

        if (!mounted) return;

        setState(() {
          _duties = mappedDuties;
          _loadingDuties = false;
          _dutiesError = null;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _loadingDuties = false;
          _dutiesError = 'Failed to load duties.';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingDuties = false;
        _dutiesError = 'Unable to connect to the server.';
      });
    }
  }

  DutyItem _mapDutyItem(Map<String, dynamic> duty) {
    final title = duty['title']?.toString() ?? 'Untitled Duty';
    final description =
        duty['description']?.toString() ?? 'No description provided.';

    final targetQuantity = duty['target_quantity'];
    final unitOfMeasure = duty['unit_of_measure']?.toString();
    final targetLabel = _buildTargetLabel(
      targetQuantity: targetQuantity,
      unitOfMeasure: unitOfMeasure,
    );

    final proofRequiredValue = duty['proof_required'];
    final proofRequired = proofRequiredValue == true ||
        proofRequiredValue == 1 ||
        proofRequiredValue == '1' ||
        proofRequiredValue?.toString().toLowerCase() == 'true';

    return DutyItem(
      id: duty['id'],
      title: title,
      description: description,
      targetLabel: targetLabel,
      proofRequired: proofRequired,
    );
  }

  String _buildTargetLabel({
    required dynamic targetQuantity,
    required String? unitOfMeasure,
  }) {
    final target = targetQuantity?.toString().trim();
    final unit = unitOfMeasure?.trim();

    if (target != null && target.isNotEmpty) {
      if (unit != null && unit.isNotEmpty) {
        return 'Target: $target $unit';
      }

      return 'Target: $target';
    }

    if (unit != null && unit.isNotEmpty) {
      return 'Unit: $unit';
    }

    return 'Target: Not specified';
  }

  Future<void> _refreshPage() async {
    await Future.wait([
      _loadUserInfo(),
      _loadDuties(),
    ]);
  }


  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Duties',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your role and section assignment',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: _loadingUser
              ? Text(
                  'Loading assignment details...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userRole,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userSection,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _openLogScreen(BuildContext context, DutyItem duty) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogAccomplishmentScreen(
          duty: {
            'id': duty.id,
            'title': duty.title,
            'proof_required': duty.proofRequired,
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDutyCard(BuildContext context, DutyItem duty) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openLogScreen(context, duty),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      duty.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                duty.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    context,
                    label: duty.targetLabel,
                    icon: Icons.flag_outlined,
                  ),
                  if (duty.proofRequired)
                    _buildBadge(
                      context,
                      label: 'Proof Required',
                      textColor: Colors.lightBlue,
                      backgroundColor: Colors.lightBlue.withOpacity(0.10),
                      borderColor: Colors.lightBlue.withOpacity(0.25),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutySection(
    BuildContext context, {
    required String title,
    required List<DutyItem> duties,
  }) {
    if (duties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title),
        ...duties.map(
          (duty) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDutyCard(context, duty),
          ),
        ),
      ],
    );
  }

  Widget _buildDutyStatus(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loadingDuties) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading duties...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_dutiesError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.errorContainer.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.error.withOpacity(0.25),
            ),
          ),
          child: Text(
            _dutiesError!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_duties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Text(
            'No duties assigned yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 18),
        _buildDutySection(
          context,
          title: 'Assigned Duties',
          duties: _duties,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildDutyStatus(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DutyItem {
  final dynamic id;
  final String title;
  final String description;
  final String targetLabel;
  final bool proofRequired;

  const DutyItem({
    this.id,
    required this.title,
    required this.description,
    required this.targetLabel,
    required this.proofRequired,
  });
}
