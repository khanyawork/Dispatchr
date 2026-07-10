import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/jobs/job_model.dart';
import 'status_badge.dart';

/// Reusable job list item (`FileManifest.md`:
/// `lib/shared/widgets/job_card.dart`), meant to be shared across the
/// client, technician, and owner job lists (README Sections 8.1–8.3) so
/// the same visual language — surface, border, status badge — appears
/// everywhere a job shows up in a list.
///
/// The inline job rows in `job_list_screen.dart`, `dashboard_screen.dart`,
/// and `request_history_screen.dart` predate this widget and can migrate
/// onto it; building this doesn't retrofit them.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.subtitle,
    this.highlightUnassigned = false,
  });

  final Job job;
  final VoidCallback onTap;

  /// Overrides the default "date · technician" subtitle — e.g. the
  /// client's history screen might just want the date.
  final String? subtitle;

  /// Outlines the card in the alert color when the job has no assigned
  /// technician (README Section 5.1: red for overdue/unassigned) —
  /// relevant on the owner's dashboard/job list, not the client's own
  /// requests.
  final bool highlightUnassigned;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    final isFlagged = highlightUnassigned && job.isUnassigned;
    final defaultSubtitle = [
      if (job.scheduledDate != null)
        DateFormatter.formatShortDate(job.scheduledDate!),
      job.technicianName ?? 'Unassigned',
    ].join(' · ');

    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isFlagged ? alert : border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.clientName,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.address,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle ?? defaultSubtitle,
                      style: TextStyle(
                        color: isFlagged ? alert : textSecondary,
                        fontSize: DesignTokens.fontSizeXs,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: job.status, dense: true),
            ],
          ),
        ),
      ),
    );
  }
}
