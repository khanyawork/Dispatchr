import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/status_badge.dart';
import '../jobs/job_provider.dart';
import '../jobs/job_repository.dart';

/// README Section 8.2's job detail screen: address, client name,
/// description, Owner-authored notes, status control (Pending -> In
/// Progress -> Completed — no skipping stages, no moving backward without
/// an Owner override), photo capture, completion notes, and one-tap
/// navigation to the job site.
///
/// Job reads/writes go through `job_repository.dart`. A
/// `technician_repository.dart` may still be worth adding later for
/// technician-specific concerns, per FileManifest.md.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  bool _notesInitialized = false;
  bool _isUpdatingStatus = false;
  bool _isUploadingPhoto = false;
  bool _isSavingNotes = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _advanceStatus(String currentStatus) async {
    final nextStatus = currentStatus == JobStatuses.pending
        ? JobStatuses.inProgress
        : JobStatuses.completed;

    setState(() {
      _isUpdatingStatus = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(jobRepositoryProvider)
          .updateStatus(widget.jobId, nextStatus);
    } catch (_) {
      setState(() => _errorMessage = "Couldn't update status. Try again.");
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() {
      _isSavingNotes = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(jobRepositoryProvider)
          .updateCompletionNotes(widget.jobId, _notesController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved.')));
      }
    } catch (_) {
      setState(() => _errorMessage = "Couldn't save notes. Try again.");
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<void> _addPhoto(List<String> existingUrls) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _errorMessage = null;
    });

    try {
      final jobRepository = ref.read(jobRepositoryProvider);
      final url = await jobRepository.uploadJobPhoto(
        jobId: widget.jobId,
        file: File(photo.path),
        fileName: photo.name,
      );
      await jobRepository.setPhotoUrls(widget.jobId, [...existingUrls, url]);
    } catch (_) {
      setState(() => _errorMessage = "Couldn't upload photo. Try again.");
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _openDirections(String address) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      body: ref.watch(jobProvider(widget.jobId)).when(
        data: (jobRow) {
          if (jobRow == null) {
            // README Section 8.2: a job that fails to load should fail
            // safely, not crash.
            return const EmptyState(
              message: 'This job could not be found.',
              icon: Icons.search_off,
            );
          }

          final job = _JobDetail.fromRow(jobRow);

          if (!_notesInitialized) {
            _notesController.text = job.completionNotes ?? '';
            _notesInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.clientName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 8),
                _AddressRow(
                  address: job.address,
                  onGetDirections: () => _openDirections(job.address),
                ),
                if (job.description != null &&
                    job.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Description',
                    child: Text(job.description!),
                  ),
                ],
                const SizedBox(height: 16),
                _Section(
                  title: 'Scheduled',
                  child: Text(
                    _formatSchedule(job.scheduledDate, job.scheduledTime),
                  ),
                ),
                if (job.ownerNotes != null && job.ownerNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Notes from Owner',
                    child: Text(job.ownerNotes!),
                  ),
                ],
                const SizedBox(height: 24),
                _Section(
                  title: 'Photos',
                  child: _PhotoGallery(
                    urls: job.photoUrls,
                    isUploading: _isUploadingPhoto,
                    onAddPhoto: () => _addPhoto(job.photoUrls),
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Completion notes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'What did you do on this job?',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isSavingNotes ? null : _saveNotes,
                        child: Text(
                          _isSavingNotes ? 'Saving...' : 'Save Notes',
                        ),
                      ),
                    ],
                  ),
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
                if (job.status != JobStatuses.completed)
                  _StatusActionButton(
                    status: job.status,
                    isSubmitting: _isUpdatingStatus,
                    onPressed: () => _advanceStatus(job.status),
                  ),
              ],
            ),
          );
        },
        loading: () => const SkeletonLoader(itemCount: 3, itemHeight: 120),
        error: (error, stackTrace) => const EmptyState(
          message: "Couldn't load this job.",
          icon: Icons.error_outline,
        ),
      ),
    );
  }
}

/// Lightweight stand-in for the row shape until `job_model.dart` exists
/// (README's `jobs` table, Section 10). Falls back to placeholder text for
/// a missing address/client name — README Section 8.2: "should never
/// happen, but the UI should fail safely rather than crash."
class _JobDetail {
  const _JobDetail({
    required this.clientName,
    required this.address,
    required this.description,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.ownerNotes,
    required this.completionNotes,
    required this.photoUrls,
  });

  final String clientName;
  final String address;
  final String? description;
  final String status;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? ownerNotes;
  final String? completionNotes;
  final List<String> photoUrls;

  factory _JobDetail.fromRow(Map<String, dynamic> row) {
    final clientName = row['client_name'] as String?;
    final address = row['address'] as String?;

    return _JobDetail(
      clientName: (clientName != null && clientName.trim().isNotEmpty)
          ? clientName
          : 'Unknown client',
      address: (address != null && address.trim().isNotEmpty)
          ? address
          : 'No address provided',
      description: row['description'] as String?,
      status: row['status'] as String? ?? JobStatuses.pending,
      scheduledDate: row['scheduled_date'] != null
          ? DateTime.tryParse(row['scheduled_date'] as String)
          : null,
      scheduledTime: row['scheduled_time'] as String?,
      ownerNotes: row['owner_notes'] as String?,
      completionNotes: row['completion_notes'] as String?,
      photoUrls: (row['photo_urls'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.onGetDirections});

  final String address;
  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(address)),
        TextButton.icon(
          onPressed: onGetDirections,
          icon: const Icon(Icons.directions_outlined, size: 18),
          label: const Text('Directions'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.urls,
    required this.isUploading,
    required this.onAddPhoto,
  });

  final List<String> urls;
  final bool isUploading;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final url in urls)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 88,
                height: 88,
                color: colors.surfaceAlt,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isUploading ? null : onAddPhoto,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: colors.surfaceAlt,
            ),
            child: isUploading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.add_a_photo_outlined,
                    color: colors.textSecondary,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Primary status-advance action using the hover/press transition from
/// README Section 5.3 — mirrors `login_screen.dart`'s `_LoginButton`. Only
/// ever advances one stage (Pending -> In Progress -> Completed); moving
/// backward requires an Owner override (README Section 8.2), which this
/// screen doesn't expose.
class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.status,
    required this.isSubmitting,
    required this.onPressed,
  });

  final String status;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final label = status == JobStatuses.pending
        ? 'Start Job'
        : 'Mark Completed';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
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
            : Text(label),
      ),
    );
  }
}

/// Minimal date/time formatting until `core/utils/date_formatter.dart`
/// exists.
String _formatSchedule(DateTime? date, String? time) {
  if (date == null && time == null) return 'Not scheduled yet';
  final parts = <String>[
    if (date != null) _formatDate(date),
    if (time != null) _formatTime(time),
  ];
  return parts.join(' at ');
}

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

/// Converts a Postgres `time` string ("14:30:00") to "2:30 PM".
String _formatTime(String time) {
  final parts = time.split(':');
  final hour24 = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
