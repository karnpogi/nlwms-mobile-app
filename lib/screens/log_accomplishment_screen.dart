import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogAccomplishmentScreen extends StatefulWidget {
  final Map<String, dynamic>? duty;
  final Map<String, dynamic>? existingLog;

  const LogAccomplishmentScreen({
    super.key,
    this.duty,
    this.existingLog,
  });

  @override
  State<LogAccomplishmentScreen> createState() =>
      _LogAccomplishmentScreenState();
}

class _LogAccomplishmentScreenState extends State<LogAccomplishmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  static const String _baseApiUrl = 'http://10.0.2.2:8000/api';

  DateTime _activityDate = DateTime.now();
  File? _proofFile;
  String? _existingProofFile;
  String? _existingProofUrl;
  bool _proofRemoved = false;
  bool _submitting = false;

  bool _loadingDuties = true;
  String? _dutiesError;
  List<Map<String, dynamic>> _duties = [];
  Map<String, dynamic>? _selectedDuty;

  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.existingLog != null;

  int? _initialDutyId() {
    final dutyId = widget.duty?['id'] ??
        widget.existingLog?['duty_template_id'] ??
        widget.existingLog?['duty_template']?['id'];

    if (dutyId == null) return null;
    return int.tryParse(dutyId.toString());
  }

  Map<String, dynamic>? get _existingLogDuty {
    final dutyTemplate = widget.existingLog?['duty_template'];

    if (dutyTemplate is Map) {
      return Map<String, dynamic>.from(dutyTemplate);
    }

    return null;
  }

  Map<String, dynamic>? get _resolvedDuty {
    return _selectedDuty ?? widget.duty ?? _existingLogDuty;
  }

  bool _toBool(dynamic value) {
    if (value == true || value == 1 || value == '1') return true;
    return value?.toString().toLowerCase() == 'true';
  }

  bool get _proofRequired {
    final duty = _resolvedDuty;

    return _toBool(duty?['proof_required']) ||
        _toBool(widget.existingLog?['proof_required']) ||
        _toBool(widget.existingLog?['duty_template']?['proof_required']);
  }

  num? get _targetQuantity {
    final duty = _resolvedDuty;
    final rawTarget = duty?['target_quantity'] ??
        widget.existingLog?['target_quantity'] ??
        widget.existingLog?['duty_template']?['target_quantity'];

    if (rawTarget == null) return null;

    final targetText = rawTarget.toString().trim();
    if (targetText.isEmpty || targetText.toLowerCase() == 'null') {
      return null;
    }

    final parsed = num.tryParse(targetText);

    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }

  bool get _quantityRequired => true;

  String get _unitOfMeasure {
    final duty = _resolvedDuty;
    final rawUnit = duty?['unit_of_measure'] ??
        widget.existingLog?['unit_of_measure'] ??
        widget.existingLog?['duty_template']?['unit_of_measure'];

    final unit = rawUnit?.toString().trim() ?? '';
    return unit.isNotEmpty ? unit : 'item(s)';
  }

  String get _targetQuantityText {
    final target = _targetQuantity;
    if (target == null) {
      return 'Required for weighted scoring. Unit: $_unitOfMeasure';
    }

    final targetText = target % 1 == 0 ? target.toInt().toString() : target.toString();
    return 'Target: $targetText $_unitOfMeasure. Required for weighted scoring.';
  }

  String get _difficultyText {
    final raw = _resolvedDuty?['difficulty_level']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Easy';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String get _weightText {
    final weight = _resolvedDuty?['weight']?.toString();
    if (weight == null || weight.trim().isEmpty) return '1 point';
    return '$weight point${weight == '1' ? '' : 's'}';
  }
  bool get _hasAnyProof => _proofFile != null || _hasExistingProof;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _quantityCtrl.text = widget.existingLog?['quantity']?.toString() ?? '';
      _remarksCtrl.text = widget.existingLog?['remarks']?.toString() ?? '';

      final rawDate = widget.existingLog?['activity_date']?.toString();
      if (rawDate != null && rawDate.isNotEmpty) {
        _activityDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }

      final rawProof = widget.existingLog?['proof_file']?.toString();
      final rawProofUrl = widget.existingLog?['proof_url']?.toString();

      if (rawProof != null && rawProof.trim().isNotEmpty) {
        _existingProofFile = rawProof;
      }

      if (rawProofUrl != null && rawProofUrl.trim().isNotEmpty) {
        _existingProofUrl = rawProofUrl;
      }
    }

    _loadAvailableDuties();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

    return token;
  }

  Future<void> _loadAvailableDuties() async {
    setState(() {
      _loadingDuties = true;
      _dutiesError = null;
    });

    try {
      final token = await _requireToken();
      final response = await http.get(
        Uri.parse('$_baseApiUrl/mobile/duties'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(_extractErrorMessage(response.body, response.statusCode));
      }

      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map<String, dynamic> ? decoded['data'] : null;

      final duties = rawData is List
          ? rawData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final initialId = _initialDutyId();
      Map<String, dynamic>? selected;

      if (initialId != null) {
        for (final duty in duties) {
          final dutyId = int.tryParse(duty['id'].toString());
          if (dutyId == initialId) {
            selected = duty;
            break;
          }
        }
      }

      selected ??= widget.duty;

      if (!mounted) return;

      setState(() {
        _duties = duties;
        _selectedDuty = selected;
        _loadingDuties = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _duties = [];
        _selectedDuty = widget.duty ?? _existingLogDuty;
        _dutiesError = e.toString().replaceFirst('Exception: ', '');
        _loadingDuties = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month]} ${date.day}, ${date.year}';
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _resolvedDutyId() {
    final duty = _resolvedDuty;

    if (duty?['id'] != null) {
      return int.tryParse(duty!['id'].toString());
    }

    if (widget.existingLog?['duty_template_id'] != null) {
      return int.tryParse(widget.existingLog!['duty_template_id'].toString());
    }

    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _activityDate = picked);
    }
  }

  Future<void> _pickProofImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _proofFile = File(picked.path);
        _proofRemoved = false;
      });
    }
  }

  void _removeProof() {
    setState(() {
      _proofFile = null;
      _existingProofFile = null;
      _existingProofUrl = null;
      _proofRemoved = true;
    });
  }

  bool get _hasExistingProof {
    return !_proofRemoved &&
        ((_existingProofFile != null && _existingProofFile!.isNotEmpty) ||
            (_existingProofUrl != null && _existingProofUrl!.isNotEmpty));
  }

  Map<String, dynamic> _buildPayload() {
    final quantityText = _quantityCtrl.text.trim();

    return {
      'duty_template_id': _resolvedDutyId(),
      'activity_date': _formatApiDate(_activityDate),
      'quantity': quantityText.isEmpty ? null : num.tryParse(quantityText),
      'remarks': _remarksCtrl.text.trim(),
      'duty_template': _resolvedDuty,
    };
  }

  String _extractErrorMessage(String responseBody, int statusCode) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;

        final errors = decoded['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) return value.first.toString();
            if (value is String && value.isNotEmpty) return value;
          }
        }
      }
    } catch (_) {}

    return 'Request failed ($statusCode).';
  }

  Future<Map<String, dynamic>> _saveLog() async {
    if (!_formKey.currentState!.validate()) {
      throw Exception('Please complete all required fields.');
    }

    final dutyId = _resolvedDutyId();
    if (dutyId == null) {
      throw Exception('Please select a task/duty.');
    }

    if (_proofRequired && !_hasAnyProof) {
      throw Exception(
        'Proof is required for this duty. Please attach a photo before submitting.',
      );
    }

    final token = await _requireToken();

    final endpoint = _isEditMode
        ? '$_baseApiUrl/mobile/logs/${widget.existingLog!['id']}'
        : '$_baseApiUrl/mobile/logs';

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['duty_template_id'] = dutyId.toString();
    request.fields['activity_date'] = _formatApiDate(_activityDate);
    request.fields['quantity'] = _quantityCtrl.text.trim();
    request.fields['remarks'] = _remarksCtrl.text.trim();

    if (_isEditMode && _proofRemoved) {
      request.fields['remove_proof'] = '1';
    }

    if (_proofFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'proof_file',
          _proofFile!.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final statusCode = streamedResponse.statusCode;

    final validStatusCodes = _isEditMode ? [200] : [200, 201];

    if (!validStatusCodes.contains(statusCode)) {
      throw Exception(_extractErrorMessage(responseBody, statusCode));
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
        return decoded;
      }
    } catch (_) {}

    return _buildPayload();
  }

  Future<void> _submitLog() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final savedLog = await _saveLog();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Accomplishment log updated successfully.'
                : 'Accomplishment log submitted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, savedLog);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Failed to update log: $message'
                : 'Failed to submit log: $message',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildDutySelector(ThemeData theme, ColorScheme cs) {
    if (_loadingDuties) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Loading assigned tasks...')),
          ],
        ),
      );
    }

    if (_dutiesError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.error.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to load assigned tasks',
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _dutiesError!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _loadAvailableDuties,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_duties.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No tasks are assigned to your job title yet. Please contact your unit head or administrator.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedId = _selectedDuty == null
        ? null
        : int.tryParse(_selectedDuty!['id'].toString());

    final itemIds = _duties
        .map((duty) => int.tryParse(duty['id'].toString()))
        .whereType<int>()
        .toSet();

    final safeSelectedId = itemIds.contains(selectedId) ? selectedId : null;

    return DropdownButtonFormField<int>(
      value: safeSelectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Task / Duty *',
        prefixIcon: Icon(Icons.assignment_turned_in_outlined),
      ),
      items: _duties.map((duty) {
        final dutyId = int.tryParse(duty['id'].toString());
        final title = duty['title']?.toString() ?? 'Untitled Duty';
        final jobTitle = duty['job_title']?.toString();

        return DropdownMenuItem<int>(
          value: dutyId,
          child: Text(
            jobTitle != null && jobTitle.trim().isNotEmpty
                ? '$title • $jobTitle'
                : title,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _submitting
          ? null
          : (value) {
              final selected = _duties.firstWhere(
                (duty) => int.tryParse(duty['id'].toString()) == value,
                orElse: () => <String, dynamic>{},
              );

              setState(() {
                _selectedDuty = selected.isEmpty ? null : selected;
                _proofRemoved = false;
              });
            },
      validator: (value) {
        if (value == null) return 'Please select a task/duty.';
        return null;
      },
    );
  }

  Widget _buildDutyMeta(ThemeData theme, ColorScheme cs) {
    final duty = _resolvedDuty;
    if (duty == null) return const SizedBox.shrink();

    final description = duty['description']?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.stacked_bar_chart, size: 16),
              label: Text('Weight: $_weightText'),
            ),
            Chip(
              avatar: const Icon(Icons.speed_outlined, size: 16),
              label: Text('Difficulty: $_difficultyText'),
            ),
            if (_proofRequired)
              Chip(
                avatar: const Icon(Icons.attachment_outlined, size: 16),
                label: const Text('Proof required'),
                backgroundColor: cs.errorContainer.withOpacity(0.50),
              ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final cardBg = cs.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.70,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Accomplishment' : 'Log Accomplishment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isEditMode)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.edit_note_outlined,
                            color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You are editing an existing accomplishment record.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Task',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Only tasks assigned to your job title are shown here.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildDutySelector(theme, cs),
                      _buildDutyMeta(theme, cs),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accomplishment Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(
                            theme.brightness == Brightness.dark ? 0.25 : 0.60,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.today_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activity Date',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_activityDate),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditMode
                                        ? 'Date is kept from the original log and cannot be changed.'
                                        : "Automatically uses today's date and cannot be changed.",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.lock_outline, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _quantityCtrl,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Quantity Completed *',
                          prefixIcon: const Icon(Icons.numbers_outlined),
                          hintText: 'Enter completed quantity',
                          helperText: _targetQuantityText,
                        ),
                        validator: (value) {
                          final quantityText = value?.trim() ?? '';

                          if (quantityText.isEmpty) {
                            return 'Quantity is required because it is used for weighted scoring.';
                          }

                          final parsed = num.tryParse(quantityText);
                          if (parsed == null) {
                            return 'Enter a valid quantity.';
                          }

                          if (parsed <= 0) {
                            return 'Quantity must be greater than 0.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _remarksCtrl,
                        enabled: !_submitting,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Remarks / Notes',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                          hintText: 'Write what was accomplished...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Remarks are required.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Supporting Proof',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_proofRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.errorContainer.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.error.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                'Required',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _proofRequired
                            ? 'This duty requires a proof attachment before submission.'
                            : 'Attach a photo or screenshot if needed for this duty.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can take a photo or choose from your gallery. Image proof will be attached to this accomplishment log.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_proofFile != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _proofFile!,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _submitting ? null : _pickProofImage,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Change'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _submitting ? null : _removeProof,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else if (_hasExistingProof)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cs.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attachment_outlined,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Proof image already attached to this log.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _submitting ? null : _pickProofImage,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Replace'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _submitting ? null : _removeProof,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickProofImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Add Proof Photo'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting || _loadingDuties ? null : _submitLog,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isEditMode
                                ? Icons.save_outlined
                                : Icons.send_outlined,
                          ),
                    label: Text(
                      _submitting
                          ? (_isEditMode ? 'Updating...' : 'Submitting...')
                          : (_isEditMode ? 'Update Accomplishment' : 'Submit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
