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

/// README Section 8.1's client home — "My Requests": active and past
/// requests at a glance, updating live via a Supabase Realtime stream so
/// status changes (Pending -> In Progress -> Completed) show up without a
/// manual refresh, per the client's "view real-time status" capability.
///
/// The repository call below still lives here rather than a dedicated
/// `client_repository.dart` — this screen only ever needs the one
/// cross-role query `job_repository.dart` already provides.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = currentUserId(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            tooltip: 'Job history',
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.clientHistory),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: AppSession.instance.signOut,
          ),
        ],
      ),
      body: userId == null
          ? const EmptyState(
              message: 'You need to be logged in to see your requests.',
              icon: Icons.lock_outline,
            )
          : ref
                .watch(clientJobsProvider(userId))
                .when(
                  data: (rows) {
                    final jobs = rows
                        .map(_ClientJob.fromRow)
                        .toList(growable: false);

                    if (jobs.isEmpty) {
                      return const EmptyState(
                        message:
                            "You haven't submitted any requests yet.\n"
                            "Tap + to request a service.",
                        icon: Icons.inbox_outlined,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: jobs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _RequestCard(
                          job: job,
                          onTap: () =>
                              context.push('/client/requests/${job.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const SkeletonLoader(),
                  error: (error, stackTrace) => const EmptyState(
                    message: "Couldn't load your requests. Pull to retry.",
                    icon: Icons.error_outline,
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New request',
        onPressed: () => context.push(AppRoutes.clientNewRequest),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Lightweight stand-in for the row shape until `job_model.dart` exists
/// (README's `jobs` table, Section 10).
class _ClientJob {
  const _ClientJob({
    required this.id,
    required this.description,
    required this.address,
    required this.status,
    required this.scheduledDate,
  });

  final String id;
  final String? description;
  final String address;
  final String status;
  final DateTime? scheduledDate;

  factory _ClientJob.fromRow(Map<String, dynamic> row) {
    return _ClientJob(
      id: row['id'] as String,
      description: row['description'] as String?,
      address: row['address'] as String? ?? '',
      status: row['status'] as String? ?? JobStatuses.pending,
      scheduledDate: row['scheduled_date'] != null
          ? DateTime.tryParse(row['scheduled_date'] as String)
          : null,
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.job, required this.onTap});

  final _ClientJob job;
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
                    child: Text(job.address, style: textTheme.titleMedium),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: job.status),
                ],
              ),
              if (job.description != null &&
                  job.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  job.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (job.status == JobStatuses.pending) ...[
                const SizedBox(height: 8),
                Text(
                  "Received — we'll confirm scheduling soon.",
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (job.scheduledDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(job.scheduledDate!),
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

/// Minimal date formatting until `core/utils/date_formatter.dart` exists.
String _formatDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
