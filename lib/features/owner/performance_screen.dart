import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_nav_menu.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'owner_repository.dart';

/// README Section 8.3's Business performance view — jobs per week,
/// completion rate, technician workload distribution, and busiest days
/// (the "Access business-level analytics" capability). Average job
/// duration is left out: it needs a started_at/completed_at timestamp the
/// schema doesn't have, and only the screens list mentions it — the
/// manifest's own description for this file and Section 8.3's
/// capabilities bullet both omit it.
class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  bool _isLoadingBusiness = true;
  String? _businessId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    try {
      final businessId = await ref
          .read(ownerRepositoryProvider)
          .fetchOwnBusinessId();

      if (!mounted) return;
      setState(() {
        _businessId = businessId;
        _isLoadingBusiness = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = "Couldn't load your business.";
        _isLoadingBusiness = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        actions: [SectionNavMenu(items: ownerSectionItems())],
      ),
      body: _isLoadingBusiness
          ? const SkeletonLoader()
          : _loadError != null
          ? EmptyState(message: _loadError!, icon: Icons.error_outline)
          : _businessId == null
          ? const EmptyState(
              message: 'No business is set up yet.',
              icon: Icons.business_outlined,
            )
          : _PerformanceBody(businessId: _businessId!),
    );
  }
}

class _PerformanceBody extends ConsumerWidget {
  const _PerformanceBody({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerRepository = ref.watch(ownerRepositoryProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ownerRepository.watchBusinessJobs(businessId),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.hasError) {
          return const EmptyState(
            message: "Couldn't load analytics. Pull to retry.",
            icon: Icons.error_outline,
          );
        }

        if (!jobSnapshot.hasData) {
          return const SkeletonLoader();
        }

        final jobs = jobSnapshot.data!;

        if (jobs.isEmpty) {
          return const EmptyState(
            message:
                "No jobs yet — analytics will show up once you've "
                'scheduled some.',
            icon: Icons.bar_chart_outlined,
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: ownerRepository.watchBusinessProfiles(businessId),
          builder: (context, profileSnapshot) {
            final technicianNames = <String, String>{
              for (final row in profileSnapshot.data ?? const [])
                if (row['role'] == AppRoles.technician)
                  row['id'] as String:
                      ((row['full_name'] as String?)?.trim().isNotEmpty ==
                          true)
                      ? row['full_name'] as String
                      : 'Unnamed technician',
            };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(jobs: jobs),
                const SizedBox(height: 24),
                _Section(
                  title: 'Jobs per week',
                  child: _WeeklyJobsChart(jobs: jobs),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Technician workload',
                  child: _WorkloadChart(
                    jobs: jobs,
                    technicianNames: technicianNames,
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Busiest days',
                  child: _BusiestDaysChart(jobs: jobs),
                ),
              ],
            );
          },
        );
      },
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
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.jobs});

  final List<Map<String, dynamic>> jobs;

  @override
  Widget build(BuildContext context) {
    final total = jobs.length;
    final completed = jobs
        .where((job) => job['status'] == JobStatuses.completed)
        .length;
    final completionRate = total == 0 ? 0 : (completed / total * 100).round();

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisWeekCount = jobs.where((job) {
      final createdAt = DateTime.tryParse(job['created_at'] as String? ?? '');
      return createdAt != null && !createdAt.isBefore(startOfWeek);
    }).length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(label: 'Jobs this week', value: '$thisWeekCount'),
        _StatTile(label: 'Completion rate', value: '$completionRate%'),
        _StatTile(label: 'Total jobs', value: '$total'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WeeklyJobsChart extends StatelessWidget {
  const _WeeklyJobsChart({required this.jobs});

  final List<Map<String, dynamic>> jobs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final scheme = Theme.of(context).colorScheme;

    final weeks = _lastSixWeekCounts(jobs);
    final maxCount = weeks
        .map((week) => week.count)
        .fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final week in weeks)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${week.count}', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      height: maxCount == 0
                          ? 4
                          : 8 + (week.count / maxCount) * 88,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      week.label,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCount {
  const _WeekCount({required this.label, required this.count});

  final String label;
  final int count;
}

List<_WeekCount> _lastSixWeekCounts(List<Map<String, dynamic>> jobs) {
  final now = DateTime.now();
  final currentWeekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));

  final weekStarts = List.generate(
    6,
    (i) => currentWeekStart.subtract(Duration(days: 7 * (5 - i))),
  );

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return weekStarts.map((start) {
    final end = start.add(const Duration(days: 7));
    final count = jobs.where((job) {
      final createdAt = DateTime.tryParse(job['created_at'] as String? ?? '');
      return createdAt != null &&
          !createdAt.isBefore(start) &&
          createdAt.isBefore(end);
    }).length;
    return _WeekCount(
      label: '${months[start.month - 1]} ${start.day}',
      count: count,
    );
  }).toList();
}

class _WorkloadChart extends StatelessWidget {
  const _WorkloadChart({required this.jobs, required this.technicianNames});

  final List<Map<String, dynamic>> jobs;
  final Map<String, String> technicianNames;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final scheme = Theme.of(context).colorScheme;

    final counts = <String, int>{};
    for (final job in jobs) {
      final techId = job['assigned_technician_id'] as String?;
      final label = techId == null
          ? 'Unassigned'
          : (technicianNames[techId] ?? 'Unknown technician');
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Text(
        'No jobs to distribute yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }

    final maxCount = entries.first.value;

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: maxCount == 0 ? 0 : entry.value / maxCount,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        // README Section 8.3: unassigned jobs are flagged
                        // in red on the owner dashboard, same rule here.
                        color: entry.key == 'Unassigned'
                            ? Theme.of(context).colorScheme.error
                            : scheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BusiestDaysChart extends StatelessWidget {
  const _BusiestDaysChart({required this.jobs});

  final List<Map<String, dynamic>> jobs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final scheme = Theme.of(context).colorScheme;

    final counts = List<int>.filled(7, 0); // Mon = index 0 .. Sun = index 6
    var haveAnyScheduled = false;
    for (final job in jobs) {
      final dateStr = job['scheduled_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      counts[date.weekday - 1]++;
      haveAnyScheduled = true;
    }

    if (!haveAnyScheduled) {
      return Text(
        'No scheduled dates yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }

    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maxCount == 0
                          ? 4
                          : 8 + (counts[i] / maxCount) * 72,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
