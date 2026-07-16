import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/section_nav_menu.dart';
import 'create_edit_job_screen.dart';
import 'owner_repository.dart';

/// All jobs for the business, filterable by date range, technician, and
/// status (README 8.3). `FileManifest.md`:
/// `lib/features/owner/job_list_screen.dart`.
class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  static const Map<String, String> _statusLabels = {
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
  };

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _technicianId;
  String? _status;

  JobListFilter get _filter => (
    fromDate: _fromDate,
    toDate: _toDate,
    technicianId: _technicianId,
    status: _status,
    clientId: null,
  );

  bool get _hasActiveFilters =>
      _fromDate != null || _toDate != null || _technicianId != null || _status != null;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _technicianId = null;
      _status = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(technicianRosterProvider);
    final jobsAsync = ref.watch(jobListProvider(_filter));
    final isDark = context.isDarkMode;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Jobs'),
        actions: [SectionNavMenu(items: ownerSectionItems())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(const CreateEditJobScreen()),
        tooltip: 'New job',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _fromDate == null || _toDate == null
                        ? 'Date range'
                        : '${DateFormatter.formatShortDate(_fromDate!)} – ${DateFormatter.formatShortDate(_toDate!)}',
                  ),
                  onPressed: _pickDateRange,
                ),
                DropdownButton<String?>(
                  value: _status,
                  hint: const Text('Status'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    for (final entry in _statusLabels.entries)
                      DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
                rosterAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (roster) => DropdownButton<String?>(
                    value: _technicianId,
                    hint: const Text('Technician'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All technicians'),
                      ),
                      for (final technician in roster)
                        DropdownMenuItem<String?>(
                          value: technician['id'] as String,
                          child: Text(
                            technician['full_name'] as String? ?? 'Unnamed',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _technicianId = value),
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Could not load jobs',
                  style: TextStyle(color: alert),
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      _hasActiveFilters
                          ? 'No jobs match these filters'
                          : 'No jobs yet',
                      style: TextStyle(color: textSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(jobListProvider(_filter).future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _JobRow(job: jobs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

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
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
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
    final isUnassigned = job['assigned_technician_id'] == null;
    final technicianName =
        (job['technician'] as Map?)?['full_name'] as String?;

    final scheduledDate = job['scheduled_date'] != null
        ? DateTime.tryParse(job['scheduled_date'] as String)
        : null;

    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(CreateEditJobScreen(jobId: job['id'] as String)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isUnassigned ? alert : border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['client_name'] as String? ?? 'Unknown client',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job['address'] as String? ?? '—',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (scheduledDate != null)
                          DateFormatter.formatShortDate(scheduledDate),
                        technicianName ?? 'Unassigned',
                      ].join(' · '),
                      style: TextStyle(
                        color: isUnassigned ? alert : textSecondary,
                        fontSize: DesignTokens.fontSizeXs,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}
