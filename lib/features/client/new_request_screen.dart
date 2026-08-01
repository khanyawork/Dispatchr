import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/app_providers.dart';
import '../../core/constants.dart';
import '../../dev/preview_data.dart';
import '../../dev/preview_mode.dart';
import '../jobs/job_repository.dart';

/// README Section 8.1's "New Request form" — description, preferred
/// date/time, service address, and optional photos of the issue.
///
/// The profile/business lookup below still talks to Supabase directly —
/// move it into `client_repository.dart` once that exists, per
/// FileManifest.md. Job creation and photo upload go through
/// `job_repository.dart`.
class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final List<XFile> _photos = [];

  bool _isLoadingProfile = true;
  String? _clientName;
  String? _businessId;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileAndBusiness();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndBusiness() async {
    if (PreviewMode.enabled) {
      setState(() {
        _clientName = PreviewIds.clientName;
        _businessId = PreviewIds.businessId;
        _isLoadingProfile = false;
      });
      return;
    }

    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;

    try {
      final profile = await client
          .from(SupabaseTables.profiles)
          .select('full_name, business_id')
          .eq('id', userId)
          .single();

      var businessId = profile['business_id'] as String?;

      // Phase 1 single-tenant fallback: this client isn't linked to a
      // business yet (no invite/business-picker flow exists), so attach
      // their request to the only business in the system. Replace once
      // Phase 3's multi-tenant business-selection flow exists.
      if (businessId == null) {
        final business = await client
            .from(SupabaseTables.businesses)
            .select('id')
            .order('created_at')
            .limit(1)
            .maybeSingle();
        businessId = business?['id'] as String?;
      }

      if (!mounted) return;
      setState(() {
        _clientName = profile['full_name'] as String? ?? 'Client';
        _businessId = businessId;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load your account. Please try again.";
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _scheduledDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _scheduledTime = time);
  }

  Future<void> _addFromGallery() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) setState(() => _photos.addAll(images));
  }

  Future<void> _addFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) setState(() => _photos.add(photo));
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_businessId == null) {
      setState(
        () => _errorMessage =
            'No business is set up to receive requests yet. Please contact support.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final jobRepository = ref.read(jobRepositoryProvider);
    final userId = PreviewMode.enabled
        ? PreviewIds.client
        : ref.read(supabaseClientProvider).auth.currentUser!.id;

    try {
      final jobId = await jobRepository.createJob({
        'business_id': _businessId,
        'client_id': userId,
        'client_name': _clientName,
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'scheduled_date': _scheduledDate == null
            ? null
            : _scheduledDate!.toIso8601String().split('T').first,
        'scheduled_time': _scheduledTime == null
            ? null
            : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:'
                  '${_scheduledTime!.minute.toString().padLeft(2, '0')}:00',
      });

      if (_photos.isNotEmpty) {
        final urls = <String>[];
        for (final photo in _photos) {
          final url = await jobRepository.uploadJobPhoto(
            jobId: jobId,
            file: File(photo.path),
            fileName: photo.name,
          );
          urls.add(url);
        }
        await jobRepository.setPhotoUrls(jobId, urls);
      }

      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Service address',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Describe the issue',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'A description is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preferred date/time (optional)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                _scheduledDate == null
                                    ? 'Choose date'
                                    : _formatDate(_scheduledDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(
                                _scheduledTime == null
                                    ? 'Choose time'
                                    : _scheduledTime!.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Photos (optional)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      _PhotoPicker(
                        photos: _photos,
                        onAdd: _showPhotoSourceSheet,
                        onRemove: (index) =>
                            setState(() => _photos.removeAt(index)),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SubmitButton(
                        isSubmitting: _isSubmitting,
                        onPressed: _submit,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Minimal date formatting until `core/utils/date_formatter.dart` exists.
String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < photos.length; i++)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photos[i].path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.cancel,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => onRemove(i),
                ),
              ),
            ],
          ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onAdd,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: colors.surfaceAlt,
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary action button using the hover/press transition from README
/// Section 5.3 — mirrors `login_screen.dart`'s `_LoginButton`. Will be
/// replaced by `shared/widgets/primary_button.dart` once that's built.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
    required this.colors,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;
  final AppColorExtension colors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return colors.primaryHover;
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onPrimary,
              ),
            )
          : const Text('Submit Request'),
    );
  }
}
