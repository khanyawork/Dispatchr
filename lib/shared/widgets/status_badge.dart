import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/jobs/job_status.dart';

/// Animated status pill for a job's [JobStatus] (README Section 5.3:
/// status transitions animate the badge color/label rather than swapping
/// abruptly). Shared across the Client, Technician, and Owner job lists.
///
/// A small leading status dot pairs with the label — the classic ops
/// dashboard treatment — so state is legible at a glance and never
/// communicated by color alone (README 5.5 accessibility).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.dense = false});

  final JobStatus status;

  /// Tighter padding/type for use inside already-dense list rows (e.g.
  /// [job_card.dart]'s trailing badge) — still shows the full label, never
  /// just an icon/dot, so state stays legible without color alone
  /// (README 5.5 accessibility).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    final color = switch (status) {
      JobStatus.inProgress => scheme.primary,
      JobStatus.completed => colors.success,
      JobStatus.pending => colors.textSecondary,
    };

    final dotSize = dense ? 5.0 : 6.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: dense ? 5 : 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              status.label,
              key: ValueKey(status),
              style:
                  (dense
                          ? Theme.of(context).textTheme.labelSmall
                          : Theme.of(context).textTheme.labelMedium)
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        height: 1.2,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
