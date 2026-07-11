import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'owner_repository.dart';

/// README Section 8.3's Client list — "clients who have requested or
/// received service" from this business. Clients aren't linked to a
/// business via `profiles.business_id` in Phase 1 (there's no
/// business-picker flow yet — see `new_request_screen.dart`'s fallback
/// logic), so this screen derives the list from the `jobs` they've
/// submitted rather than a business-scoped profiles query.
class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
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
        title: const Text('Clients'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: AppSession.instance.signOut,
          ),
        ],
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
          : _ClientList(businessId: _businessId!),
    );
  }
}

class _ClientList extends ConsumerWidget {
  const _ClientList({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerRepository = ref.watch(ownerRepositoryProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ownerRepository.watchBusinessJobs(businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            message: "Couldn't load your clients. Pull to retry.",
            icon: Icons.error_outline,
          );
        }

        if (!snapshot.hasData) {
          return const SkeletonLoader();
        }

        final clients = _summarize(snapshot.data!);

        if (clients.isEmpty) {
          return const EmptyState(
            message: "No clients yet — they'll appear here once someone "
                'submits a request.',
            icon: Icons.people_outline,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ClientCard(
            key: ValueKey(clients[index].clientId),
            summary: clients[index],
          ),
        );
      },
    );
  }
}

/// Aggregated view of a client's request history, derived entirely from
/// `jobs` rows (see the class doc comment on [ClientListScreen] for why).
class _ClientSummary {
  const _ClientSummary({
    required this.clientId,
    required this.name,
    required this.totalRequests,
    required this.activeRequests,
    required this.lastRequestAt,
  });

  final String clientId;
  final String name;
  final int totalRequests;
  final int activeRequests;
  final DateTime lastRequestAt;
}

List<_ClientSummary> _summarize(List<Map<String, dynamic>> jobRows) {
  final byClient = <String, List<Map<String, dynamic>>>{};
  for (final row in jobRows) {
    final clientId = row['client_id'] as String?;
    // A job with no client (e.g. an Owner-created walk-in) isn't a
    // "client who has requested service" — skip it.
    if (clientId == null) continue;
    byClient.putIfAbsent(clientId, () => []).add(row);
  }

  final summaries = byClient.entries.map((entry) {
    final rows = entry.value
      ..sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
    final latest = rows.first;
    final name = latest['client_name'] as String?;

    return _ClientSummary(
      clientId: entry.key,
      name: (name != null && name.trim().isNotEmpty)
          ? name
          : 'Unknown client',
      totalRequests: rows.length,
      activeRequests: rows
          .where((row) => row['status'] != JobStatuses.completed)
          .length,
      lastRequestAt: DateTime.parse(latest['created_at'] as String),
    );
  }).toList();

  summaries.sort((a, b) => b.lastRequestAt.compareTo(a.lastRequestAt));
  return summaries;
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({super.key, required this.summary});

  final _ClientSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.name, style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${summary.totalRequests} '
              'request${summary.totalRequests == 1 ? '' : 's'}'
              '${summary.activeRequests > 0 ? ' · ${summary.activeRequests} active' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last request ${_formatDate(summary.lastRequestAt)}',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
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
