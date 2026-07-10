import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/jobs/job_status.dart';

/// Animated status pill for Pending → In Progress → Completed
/// (README Section 5.3: "animate the status badge color/label change
/// rather than an abrupt swap"). `FileManifest.md`:
/// `lib/shared/widgets/status_badge.dart`.
///
/// Centralizes the status-pill styling duplicated inline across
/// `request_detail_screen.dart`, `job_list_screen.dart`, and
/// `dashboard_screen.dart` — those can migrate onto this widget next.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.dense = false});

  final JobStatus status;

  /// Tighter padding/icon/text for list rows; the default size suits
  /// detail screens.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = switch (status) {
      JobStatus.completed =>
        isDark ? DesignTokens.successDark : DesignTokens.successLight,
      JobStatus.inProgress =>
        isDark ? DesignTokens.primaryDark : DesignTokens.primaryLight,
      JobStatus.pending =>
        isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight,
    };

    return AnimatedContainer(
      duration: DesignTokens.statusTransitionDuration,
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: dense ? 6 : 8, color: color),
          SizedBox(width: dense ? 4 : 6),
          AnimatedSwitcher(
            duration: DesignTokens.statusTransitionDuration,
            child: Text(
              status.label,
              key: ValueKey(status),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: dense ? DesignTokens.fontSizeXs : DesignTokens.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
