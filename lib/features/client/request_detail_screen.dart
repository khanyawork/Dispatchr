import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import 'client_repository.dart';

/// Request/job detail: status, assigned technician, photos, notes
/// (README 8.1). `FileManifest.md`:
/// `lib/features/client/request_detail_screen.dart`.
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(requestDetailProvider(jobId));
    final alertColor = context.isDarkMode
        ? DesignTokens.alertDark
        : DesignTokens.alertLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load this request',
            style: TextStyle(color: alertColor),
          ),
        ),
        data: (job) {
          if (job == null) {
            return const Center(child: Text('This request no longer exists'));
          }
          return _RequestDetailBody(jobId: jobId, job: job);
        },
      ),
    );
  }
}

class _RequestDetailBody extends ConsumerWidget {
  const _RequestDetailBody({required this.jobId, required this.job});

  final String jobId;
  final JobRecord job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = job['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    final scheduledDate = job['scheduled_date'] != null
        ? DateTime.tryParse(job['scheduled_date'] as String)
        : null;
    final scheduledTimeRaw = job['scheduled_time'] as String?;
    final photoUrls = (job['photo_urls'] as List?)?.cast<String>() ?? const [];
    final technicianName =
        (job['technician'] as Map?)?['full_name'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusBadge(status: status),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Address',
          child: Text(job['address'] as String? ?? '—'),
        ),
        if (job['description'] != null &&
            (job['description'] as String).trim().isNotEmpty)
          _DetailSection(
            title: 'Description',
            child: Text(job['description'] as String),
          ),
        if (scheduledDate != null)
          _DetailSection(
            title: 'Scheduled',
            child: Text(
              scheduledTimeRaw != null
                  ? '${DateFormatter.formatShortDate(scheduledDate)} at ${_formatPostgresTime(scheduledTimeRaw)}'
                  : DateFormatter.formatShortDate(scheduledDate),
            ),
          ),
        _DetailSection(
          title: 'Technician',
          child: Text(technicianName ?? 'Not yet assigned'),
        ),
        if (photoUrls.isNotEmpty)
          _DetailSection(
            title: 'Photos',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in photoUrls)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        if (isPending) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reschedule(context, ref),
                  child: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.isDarkMode
                        ? DesignTokens.alertDark
                        : DesignTokens.alertLight,
                  ),
                  onPressed: () => _confirmCancel(context, ref),
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _formatPostgresTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateFormatter.formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !context.mounted) return;

    try {
      await ref
          .read(clientRepositoryProvider)
          .rescheduleRequest(jobId, date: date, time: time);
      if (context.mounted) {
        context.showSuccessSnackBar('Request rescheduled');
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not reschedule this request');
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(clientRepositoryProvider).cancelRequest(jobId);
      if (context.mounted) {
        context.showSuccessSnackBar('Request cancelled');
        context.pop();
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not cancel this request');
      }
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.isDarkMode
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final textPrimary = context.isDarkMode
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: textSecondary,
              fontSize: DesignTokens.fontSizeXs,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: TextStyle(
              color: textPrimary,
              fontSize: DesignTokens.fontSizeMd,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Animated status pill for Pending → In Progress → Completed
/// (README Section 5.3: "animate the status badge color/label change
/// rather than an abrupt swap"). A full-featured version of this belongs in
/// `shared/widgets/status_badge.dart`; this is a local, minimal stand-in
/// until that shared widget exists.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  static const Map<String, String> _labels = {
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = switch (status) {
      'completed' => isDark ? DesignTokens.successDark : DesignTokens.successLight,
      'in_progress' => isDark ? DesignTokens.primaryDark : DesignTokens.primaryLight,
      _ => isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight,
    };

    return AnimatedContainer(
      duration: DesignTokens.statusTransitionDuration,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: DesignTokens.statusTransitionDuration,
            child: Text(
              _labels[status] ?? status,
              key: ValueKey(status),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
