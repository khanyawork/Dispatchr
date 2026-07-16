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
/// Composition: client name over an icon-annotated address line and meta
/// line, trailing status pill. On pointer hover (desktop command-center
/// use) the hairline border warms toward the primary token and a faint
/// shadow lifts the card — a 180ms ease-out per README 5.3, no snap.
///
/// The inline job rows in `job_list_screen.dart`, `dashboard_screen.dart`,
/// and `request_history_screen.dart` predate this widget and can migrate
/// onto it; building this doesn't retrofit them.
class JobCard extends StatefulWidget {
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
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final job = widget.job;
    final surface = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceLight;
    final primary = isDark
        ? DesignTokens.primaryDark
        : DesignTokens.primaryLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    final isFlagged = widget.highlightUnassigned && job.isUnassigned;
    final defaultSubtitle = [
      if (job.scheduledDate != null)
        DateFormatter.formatShortDate(job.scheduledDate!),
      job.technicianName ?? 'Unassigned',
    ].join(' · ');

    final borderColor = isFlagged
        ? alert
        : (_isHovered ? primary.withValues(alpha: 0.55) : border);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: DesignTokens.hoverTransitionDuration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: (isDark || isFlagged)
              ? const <BoxShadow>[]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isHovered ? 0.08 : 0.04,
                    ),
                    blurRadius: _isHovered ? 12 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
        ),
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: DesignTokens.hoverTransitionDuration,
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(14),
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
                            letterSpacing: -0.1,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.address,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: DesignTokens.fontSizeSm,
                                  height: 1.35,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isFlagged
                                  ? Icons.error_outline
                                  : Icons.schedule_outlined,
                              size: 13,
                              color: isFlagged ? alert : textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.subtitle ?? defaultSubtitle,
                                style: TextStyle(
                                  color: isFlagged ? alert : textSecondary,
                                  fontSize: DesignTokens.fontSizeXs,
                                  fontWeight: isFlagged
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  letterSpacing: 0.2,
                                  height: 1.35,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
        ),
      ),
    );
  }
}
