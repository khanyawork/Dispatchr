import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import 'create_edit_job_screen.dart';
import 'job_list_screen.dart';
import 'owner_repository.dart';

/// Owner command-center home: today's jobs at a glance, technician status,
/// and overdue/unassigned alerts in red (README 8.3, Section 5.1).
/// `FileManifest.md`: `lib/features/owner/dashboard_screen.dart`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'All jobs',
            onPressed: () => context.push(const JobListScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(const CreateEditJobScreen()),
        tooltip: 'New job',
        child: const Icon(Icons.add),
      ),
      // Owner screens are the command-center surface, used from a desktop
      // window as often as a phone (README Section 4), so lay out as two
      // columns once there's room for the technician panel beside the
      // job feed rather than stacking everything vertically.
      body: context.isDesktop
          ? const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _MainColumn(),
                ),
                VerticalDivider(width: 1),
                SizedBox(width: 320, child: _TechnicianPanel()),
              ],
            )
          : const _MainColumn(showTechnicianPanel: true),
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({this.showTechnicianPanel = false});

  final bool showTechnicianPanel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(title: 'Alerts'),
        const _AlertsSection(),
        const SizedBox(height: 24),
        const _SectionHeader(title: "Today's Jobs"),
        const _TodaysJobsSection(),
        if (showTechnicianPanel) ...[
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Technicians'),
          const _TechnicianPanel(),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return alertsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        'Could not load alerts',
        style: TextStyle(color: alert),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Text(
            'Nothing needs attention',
            style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
          );
        }
        return Column(
          children: [
            for (final job in jobs) ...[
              _AlertCard(job: job),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.job});

  final JobRecord job;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;

    final isUnassigned = job['assigned_technician_id'] == null;
    final reason = isUnassigned ? 'Unassigned' : 'Overdue';

    return Material(
      color: alert.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(CreateEditJobScreen(jobId: job['id'] as String)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: alert),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: alert, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${job['client_name'] ?? 'Unknown client'} — ${job['address'] ?? ''}',
                  style: TextStyle(color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reason,
                style: TextStyle(color: alert, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaysJobsSection extends ConsumerWidget {
  const _TodaysJobsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(todaysJobsProvider);
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return jobsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        'Could not load today\'s jobs',
        style: TextStyle(color: alert),
      ),
      data: (jobs) {
        // A genuine day off, not an error (README 8.3 empty states).
        if (jobs.isEmpty) {
          return Text(
            'No jobs scheduled today',
            style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
          );
        }
        return Column(
          children: [
            for (final job in jobs) ...[
              _TodayJobCard(job: job),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _TodayJobCard extends StatelessWidget {
  const _TodayJobCard({required this.job});

  final JobRecord job;

  static const Map<String, String> _statusLabels = {
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final success = isDark
        ? DesignTokens.successDark
        : DesignTokens.successLight;
    final primary = isDark
        ? DesignTokens.primaryDark
        : DesignTokens.primaryLight;

    final status = job['status'] as String? ?? 'pending';
    final statusColor = switch (status) {
      'completed' => success,
      'in_progress' => primary,
      _ => textSecondary,
    };
    final technicianName =
        (job['technician'] as Map?)?['full_name'] as String?;
    final rawTime = job['scheduled_time'] as String?;

    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(CreateEditJobScreen(jobId: job['id'] as String)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  rawTime != null ? _formatTime(rawTime) : '—',
                  style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['client_name'] as String? ?? 'Unknown client',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      technicianName ?? 'Unassigned',
                      style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeXs),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _statusLabels[status] ?? status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(String postgresTime) {
    final parts = postgresTime.split(':');
    if (parts.length < 2) return postgresTime;
    return DateFormatter.formatTimeOfDay(
      TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );
  }
}

class _TechnicianPanel extends ConsumerWidget {
  const _TechnicianPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(technicianRosterProvider);
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          'Could not load technicians',
          style: TextStyle(color: alert),
        ),
        data: (roster) {
          if (roster.isEmpty) {
            return Text(
              'No technicians yet',
              style: TextStyle(color: textSecondary),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final technician in roster) _TechnicianRow(technician: technician),
            ],
          );
        },
      ),
    );
  }
}

class _TechnicianRow extends StatelessWidget {
  const _TechnicianRow({required this.technician});

  final TechnicianRecord technician;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final success = isDark
        ? DesignTokens.successDark
        : DesignTokens.successLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    // `profiles.is_available` extends the illustrative schema in README
    // Section 10 (see owner_repository.dart / technician_repository.dart);
    // defaults to available until that column exists.
    final isAvailable = technician['is_available'] as bool? ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isAvailable ? success : textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              technician['full_name'] as String? ?? 'Unnamed',
              style: TextStyle(color: textPrimary),
            ),
          ),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeXs),
          ),
        ],
      ),
    );
  }
}
