import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/app_providers.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/status_badge.dart';
import '../jobs/job_provider.dart';

/// README Section 8.2's technician home — "My Jobs": today's assigned jobs
/// by default, with a date filter to browse upcoming/past jobs. Only shows
/// jobs assigned to the signed-in technician (never another technician's
/// jobs or the full business list), updating live via a Supabase Realtime
/// stream so an Owner's reassignment or status override shows up
/// immediately.
class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());

  bool get _isToday => _isSameDate(_selectedDate, DateTime.now());

  void _shiftDay(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = _dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final userId = currentUserId(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: AppSession.instance.signOut,
          ),
        ],
      ),
      body: userId == null
          ? const EmptyState(
              message: 'You need to be logged in to see your jobs.',
              icon: Icons.lock_outline,
            )
          : Column(
              children: [
                _DateFilterBar(
                  selectedDate: _selectedDate,
                  isToday: _isToday,
                  onPrevious: () => _shiftDay(-1),
                  onNext: () => _shiftDay(1),
                  onPickDate: _pickDate,
                  onJumpToToday: () => setState(
                    () => _selectedDate = _dateOnly(DateTime.now()),
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(technicianJobsProvider(userId))
                      .when(
                        data: (rows) {
                          final jobs = rows
                              .map(_TechnicianJob.fromRow)
                              .where(
                                (job) =>
                                    job.scheduledDate != null &&
                                    _isSameDate(
                                      job.scheduledDate!,
                                      _selectedDate,
                                    ),
                              )
                              .toList(growable: false);

                          if (jobs.isEmpty) {
                            return EmptyState(
                              message: _isToday
                                  ? 'No jobs today — enjoy your day off!'
                                  : 'No jobs scheduled for this day.',
                              icon: _isToday
                                  ? Icons.beach_access_outlined
                                  : Icons.event_busy_outlined,
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: jobs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              return _JobCard(
                                job: job,
                                onTap: () => context.push(
                                  '/technician/jobs/${job.id}',
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const SkeletonLoader(),
                        error: (error, stackTrace) => const EmptyState(
                          message: "Couldn't load your jobs. Pull to retry.",
                          icon: Icons.error_outline,
                        ),
                      ),
                ),
              ],
            ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Lightweight stand-in for the row shape until `job_model.dart` exists
/// (README's `jobs` table, Section 10). Falls back to placeholder text for
/// a missing address/client name — README Section 8.2: "should never
/// happen, but the UI should fail safely rather than crash."
class _TechnicianJob {
  const _TechnicianJob({
    required this.id,
    required this.clientName,
    required this.address,
    required this.description,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  final String id;
  final String clientName;
  final String address;
  final String? description;
  final String status;
  final DateTime? scheduledDate;
  final String? scheduledTime;

  factory _TechnicianJob.fromRow(Map<String, dynamic> row) {
    final clientName = row['client_name'] as String?;
    final address = row['address'] as String?;

    return _TechnicianJob(
      id: row['id'] as String,
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
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final _TechnicianJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.clientName, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          job.address,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: job.status),
                ],
              ),
              if (job.description != null &&
                  job.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  job.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (job.scheduledTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(job.scheduledTime!),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal time formatting until `core/utils/date_formatter.dart` exists.
/// Converts a Postgres `time` string ("14:30:00") to "2:30 PM".
String _formatTime(String time) {
  final parts = time.split(':');
  final hour24 = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.selectedDate,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
    required this.onJumpToToday,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final VoidCallback onJumpToToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: InkWell(
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isToday ? 'Today' : _formatFullDate(selectedDate),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
          if (!isToday)
            TextButton(onPressed: onJumpToToday, child: const Text('Today')),
        ],
      ),
    );
  }
}

String _formatFullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
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
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
