import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/router.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'admin_repository.dart';

/// README Section 8.4's Audit log viewer: every cross-tenant access or
/// action an Administrator has taken, with a timestamp and reason
/// ("every access is logged with timestamp and reason, never silent").
/// Read-only complement to the writes `user_management_screen.dart` and
/// `subscription_billing_screen.dart` already make into
/// `admin_audit_log`.
///
/// NOTE: like the other two, this is one of the Admin screens README
/// Section 8.4 / FileManifest.md defer to Phase 3 — built ahead of that
/// guidance at explicit request. Unlike those two, no new migration was
/// needed: `admin_audit_log` and its RLS policy already existed
/// (0004_admin_audit_log.sql, 0003_rls_policies.sql).
///
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminRepository = ref.watch(adminRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: AppSession.instance.signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by business, admin, or reason',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminRepository.watchAuditLog(),
              builder: (context, logSnapshot) {
                if (logSnapshot.hasError) {
                  return const EmptyState(
                    message: "Couldn't load the audit log. Pull to retry.",
                    icon: Icons.error_outline,
                  );
                }

                if (!logSnapshot.hasData) {
                  return const SkeletonLoader();
                }

                final logRows = logSnapshot.data!;

                if (logRows.isEmpty) {
                  return const EmptyState(
                    message: 'No audit entries yet.',
                    icon: Icons.fact_check_outlined,
                  );
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: adminRepository.watchAllProfiles(),
                  builder: (context, profileSnapshot) {
                    final adminNames = <String, String>{
                      for (final row in profileSnapshot.data ?? const [])
                        row['id'] as String:
                            ((row['full_name'] as String?)
                                    ?.trim()
                                    .isNotEmpty ==
                                true)
                            ? row['full_name'] as String
                            : 'Unnamed admin',
                    };

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: adminRepository.watchAllBusinesses(),
                      builder: (context, businessSnapshot) {
                        final businessNames = <String, String>{
                          for (final row
                              in businessSnapshot.data ?? const [])
                            row['id'] as String:
                                (row['name'] as String?) ??
                                    'Unnamed business',
                        };

                        var entries =
                            logRows
                                .map(
                                  (row) => _AuditEntry.fromRow(
                                    row,
                                    adminNames,
                                    businessNames,
                                  ),
                                )
                                .toList()
                              ..sort(
                                (a, b) =>
                                    b.accessedAt.compareTo(a.accessedAt),
                              );

                        if (_query.isNotEmpty) {
                          entries = entries
                              .where(
                                (entry) =>
                                    entry.adminName.toLowerCase().contains(
                                      _query,
                                    ) ||
                                    entry.businessName
                                        .toLowerCase()
                                        .contains(_query) ||
                                    entry.reason.toLowerCase().contains(
                                      _query,
                                    ),
                              )
                              .toList();
                        }

                        if (entries.isEmpty) {
                          return EmptyState(
                            message: 'No audit entries match "$_query".',
                            icon: Icons.search_off,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: entries.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _AuditEntryCard(
                            key: ValueKey(entries[index].id),
                            entry: entries[index],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight stand-in for the row shape until a shared model exists.
class _AuditEntry {
  const _AuditEntry({
    required this.id,
    required this.adminName,
    required this.businessName,
    required this.reason,
    required this.accessedAt,
  });

  final String id;
  final String adminName;
  final String businessName;
  final String reason;
  final DateTime accessedAt;

  factory _AuditEntry.fromRow(
    Map<String, dynamic> row,
    Map<String, String> adminNames,
    Map<String, String> businessNames,
  ) {
    final adminId = row['admin_id'] as String?;
    final businessId = row['business_id'] as String?;
    final reason = row['reason'] as String?;

    return _AuditEntry(
      id: row['id'] as String,
      adminName: adminId != null
          ? (adminNames[adminId] ?? 'Unknown admin')
          : 'Unknown admin',
      businessName: businessId != null
          ? (businessNames[businessId] ?? 'Unknown business')
          : 'Unknown business',
      reason: (reason != null && reason.trim().isNotEmpty)
          ? reason
          : 'No reason given',
      accessedAt: DateTime.parse(row['accessed_at'] as String),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({super.key, required this.entry});

  final _AuditEntry entry;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.businessName,
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(entry.accessedAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.adminName,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(entry.reason),
          ],
        ),
      ),
    );
  }
}

/// Minimal timestamp formatting until `core/utils/date_formatter.dart`
/// exists. `accessed_at` is a `timestamptz`, so this converts to the
/// device's local time before displaying.
String _formatTimestamp(DateTime dateTime) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = dateTime.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year}, '
      '$hour12:$minute $period';
}
