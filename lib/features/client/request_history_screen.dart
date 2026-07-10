import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import 'client_repository.dart';
import 'request_detail_screen.dart';

/// Past/completed requests (README 8.1: "View job history, including past
/// addresses, descriptions, and outcomes"). `FileManifest.md`:
/// `lib/features/client/request_history_screen.dart`.
class RequestHistoryScreen extends ConsumerWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(requestHistoryProvider);
    final alertColor = context.isDarkMode
        ? DesignTokens.alertDark
        : DesignTokens.alertLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Job History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load job history',
            style: TextStyle(color: alertColor),
          ),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const _EmptyHistory();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(requestHistoryProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _HistoryCard(job: jobs[index]),
            ),
          );
        },
      ),
    );
  }
}

/// First-time client with no completed jobs yet — reads as "no history so
/// far," not an error (README 8.1 "Empty states to design for").
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.isDarkMode
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              'No completed jobs yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: DesignTokens.fontSizeMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.job});

  final JobRecord job;

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

    final scheduledDate = job['scheduled_date'] != null
        ? DateTime.tryParse(job['scheduled_date'] as String)
        : null;

    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(RequestDetailScreen(jobId: job['id'] as String)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['address'] as String? ?? 'Unknown address',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduledDate != null
                          ? DateFormatter.formatDate(scheduledDate)
                          : 'No date recorded',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: success, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
