import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../core/constants.dart';

/// Animated status pill for a job's `status` value (README Section 5.3:
/// status transitions animate the badge color/label rather than swapping
/// abruptly). Shared across the Client, Technician, and Owner job lists.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  static const _labels = {
    JobStatuses.pending: 'Pending',
    JobStatuses.inProgress: 'In Progress',
    JobStatuses.completed: 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    final color = switch (status) {
      JobStatuses.inProgress => scheme.primary,
      JobStatuses.completed => colors.success,
      _ => colors.textSecondary,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          _labels[status] ?? status,
          key: ValueKey(status),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
