import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LogAccomplishmentScreen extends StatefulWidget {
  final Map<String, dynamic>? duty;

  const LogAccomplishmentScreen({
    super.key,
    this.duty,
  });

  @override
  State<LogAccomplishmentScreen> createState() =>
      _LogAccomplishmentScreenState();
}

class _LogAccomplishmentScreenState extends State<LogAccomplishmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dutyTitleCtrl;
  late final TextEditingController _frequencyCtrl;
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  DateTime _activityDate = DateTime.now();
  File? _proofFile;

  bool _savingDraft = false;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _dutyTitleCtrl = TextEditingController(
      text: widget.duty?['title']?.toString() ?? '',
    );

    _frequencyCtrl = TextEditingController(
      text: widget.duty?['frequency']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _dutyTitleCtrl.dispose();
    _frequencyCtrl.dispose();
    _quantityCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
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
      setState(() => _proofFile = File(picked.path));
    }
  }

  void _removeProof() {
    setState(() => _proofFile = null);
  }

  Map<String, dynamic> _buildPayload(String status) {
    return {
      'duty_title': _dutyTitleCtrl.text.trim(),
      'frequency': _frequencyCtrl.text.trim(),
      'activity_date': _activityDate.toIso8601String(),
      'quantity': int.tryParse(_quantityCtrl.text.trim()) ?? 0,
      'remarks': _remarksCtrl.text.trim(),
      'proof_file_path': _proofFile?.path,
      'status': status,
    };
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _savingDraft = true);

    try {
      final payload = _buildPayload('draft');

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accomplishment log saved as draft.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, payload);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final payload = _buildPayload('submitted');

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accomplishment log submitted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, payload);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit log: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        title: const Text('Log Accomplishment'),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duty Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dutyTitleCtrl,
                        readOnly: widget.duty != null,
                        decoration: const InputDecoration(
                          labelText: 'Duty Title',
                          prefixIcon: Icon(Icons.library_books_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Duty title is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _frequencyCtrl,
                        readOnly: widget.duty != null,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          prefixIcon: Icon(Icons.repeat_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Frequency is required.';
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
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.25),
                    ),
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
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
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
                              const Icon(Icons.calendar_month_outlined),
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
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Completed',
                          prefixIcon: Icon(Icons.numbers_outlined),
                          hintText: 'Enter completed quantity',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required.';
                          }

                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid quantity.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _remarksCtrl,
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
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supporting Proof',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attach a photo or screenshot if required for this duty.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_proofFile == null)
                        OutlinedButton.icon(
                          onPressed: _pickProofImage,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Upload Proof'),
                        )
                      else
                        Column(
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
                                    onPressed: _pickProofImage,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Change'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _removeProof,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_savingDraft || _submitting)
                            ? null
                            : _saveDraft,
                        child: _savingDraft
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_savingDraft || _submitting)
                            ? null
                            : _submitLog,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}