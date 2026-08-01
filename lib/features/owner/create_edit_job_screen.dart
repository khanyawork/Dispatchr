import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import 'owner_repository.dart';

/// Job creation/edit form (README 8.3). `FileManifest.md`:
/// `lib/features/owner/create_edit_job_screen.dart`.
///
/// Pass [jobId] to edit an existing job (fields prefill, a delete action
/// appears, and status becomes editable for a manual override); omit it to
/// create a new job, which always starts `pending` per the `jobs.status`
/// default (README Section 10).
class CreateEditJobScreen extends ConsumerStatefulWidget {
  const CreateEditJobScreen({super.key, this.jobId});

  final String? jobId;

  bool get isEditing => jobId != null;

  @override
  ConsumerState<CreateEditJobScreen> createState() =>
      _CreateEditJobScreenState();
}

class _CreateEditJobScreenState extends ConsumerState<CreateEditJobScreen> {
  static const List<String> _statusOptions = [
    'pending',
    'in_progress',
    'completed',
  ];
  static const Map<String, String> _statusLabels = {
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
  };

  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String? _assignedTechnicianId;
  String _status = 'pending';
  bool _isSaving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefillFrom(JobRecord job) {
    if (_prefilled) return;
    _prefilled = true;
    _clientNameController.text = job['client_name'] as String? ?? '';
    _addressController.text = job['address'] as String? ?? '';
    _descriptionController.text = job['description'] as String? ?? '';
    _assignedTechnicianId = job['assigned_technician_id'] as String?;
    _status = job['status'] as String? ?? 'pending';

    final rawDate = job['scheduled_date'] as String?;
    if (rawDate != null) _scheduledDate = DateTime.tryParse(rawDate);

    final rawTime = job['scheduled_time'] as String?;
    if (rawTime != null) {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        _scheduledTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final repository = ref.read(ownerRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repository.updateJob(
          widget.jobId!,
          clientName: _clientNameController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedTechnicianId: _assignedTechnicianId,
          scheduledDate: _scheduledDate,
          scheduledTime: _scheduledTime,
          status: _status,
        );
      } else {
        await repository.createJob(
          clientName: _clientNameController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedTechnicianId: _assignedTechnicianId,
          scheduledDate: _scheduledDate,
          scheduledTime: _scheduledTime,
        );
      }
      if (mounted) {
        context.showSuccessSnackBar(
          widget.isEditing ? 'Job updated' : 'Job created',
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) context.showErrorSnackBar('Could not save this job');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this job?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(ownerRepositoryProvider).deleteJob(widget.jobId!);
      if (mounted) {
        context.showSuccessSnackBar('Job deleted');
        context.pop();
      }
    } catch (_) {
      if (mounted) context.showErrorSnackBar('Could not delete this job');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(technicianRosterProvider);
    final jobAsync = widget.isEditing
        ? ref.watch(jobByIdProvider(widget.jobId!))
        : null;

    if (jobAsync != null) {
      final job = jobAsync.valueOrNull;
      if (job != null) _prefillFrom(job);
    }

    final isLoadingJob = widget.isEditing && (jobAsync?.isLoading ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Job' : 'New Job'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : _confirmDelete,
              tooltip: 'Delete job',
            ),
        ],
      ),
      body: isLoadingJob
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: 'Client name'),
                    validator: (v) => Validators.required(v, fieldName: 'Client name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Service address'),
                    validator: Validators.address,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: Validators.jobDescription,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          label: 'Date',
                          value: _scheduledDate == null
                              ? 'Select date'
                              : DateFormatter.formatShortDate(_scheduledDate!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerField(
                          label: 'Time',
                          value: _scheduledTime == null
                              ? 'Select time'
                              : DateFormatter.formatTimeOfDay(_scheduledTime!),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  rosterAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) =>
                        const Text('Could not load technician list'),
                    data: (roster) => DropdownButtonFormField<String?>(
                      initialValue: _assignedTechnicianId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned technician',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        for (final technician in roster)
                          DropdownMenuItem<String?>(
                            value: technician['id'] as String,
                            child: Text(
                              technician['full_name'] as String? ?? 'Unnamed',
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _assignedTechnicianId = value),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status (manual override)',
                      ),
                      items: [
                        for (final status in _statusOptions)
                          DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabels[status]!),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Save Changes' : 'Create Job'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: border),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: value.startsWith('Select') ? textSecondary : textPrimary,
          ),
        ),
      ),
    );
  }
}
