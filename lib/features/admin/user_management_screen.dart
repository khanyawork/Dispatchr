import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'admin_repository.dart';

/// README Section 8.4's User management: search/manage users across every
/// business tenant (e.g. "resetting a locked-out Owner's access").
///
/// NOTE: README Section 8.4 explicitly defers the Admin screens to Phase 3
/// ("you do not need to build this role's UI in Phase 1 ... defer the
/// actual admin screens until you're onboarding a second real business"),
/// and FileManifest.md says the same. This was built ahead of that
/// guidance at explicit request.
///
/// "Resetting access" here means reactivating a deactivated account
/// (`profiles.is_active`) — not a password reset. A real auth/password
/// reset needs the Supabase service_role key, which must never ship
/// inside a client app; that has to be a server-side Edge Function, not
/// something this screen can safely do.
///
/// Every reactivate/deactivate writes to `admin_audit_log` with a
/// required reason (README Section 8.4: "every access is logged with
/// timestamp and reason, never silent"). Merely browsing/searching the
/// list isn't logged — only the consequential action is.
///
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
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
        title: const Text('User Management'),
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
                hintText: 'Search users by name',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminRepository.watchAllProfiles(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  return const EmptyState(
                    message: "Couldn't load users. Pull to retry.",
                    icon: Icons.error_outline,
                  );
                }

                if (!profileSnapshot.hasData) {
                  return const SkeletonLoader();
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: adminRepository.watchAllBusinesses(),
                  builder: (context, businessSnapshot) {
                    final businessNames = <String, String>{
                      for (final row in businessSnapshot.data ?? const [])
                        row['id'] as String:
                            (row['name'] as String?) ?? 'Unnamed business',
                    };

                    var users = profileSnapshot.data!
                        .map((row) => _AdminUser.fromRow(row, businessNames))
                        .toList();

                    if (_query.isNotEmpty) {
                      users = users
                          .where(
                            (user) =>
                                user.fullName.toLowerCase().contains(_query),
                          )
                          .toList();
                    }

                    users.sort((a, b) => a.fullName.compareTo(b.fullName));

                    if (users.isEmpty) {
                      return EmptyState(
                        message: _query.isEmpty
                            ? 'No users on the platform yet.'
                            : 'No users match "$_query".',
                        icon: Icons.person_search_outlined,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _UserCard(
                        key: ValueKey(users[index].id),
                        user: users[index],
                      ),
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

/// Lightweight stand-in for the row shape until a shared profile model
/// exists.
class _AdminUser {
  const _AdminUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.businessName,
    required this.businessId,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String role;
  final String? businessName;
  final String? businessId;
  final bool isActive;

  factory _AdminUser.fromRow(
    Map<String, dynamic> row,
    Map<String, String> businessNames,
  ) {
    final name = row['full_name'] as String?;
    final businessId = row['business_id'] as String?;

    return _AdminUser(
      id: row['id'] as String,
      fullName: (name != null && name.trim().isNotEmpty)
          ? name
          : 'Unnamed user',
      role: row['role'] as String? ?? 'unknown',
      businessName: businessId != null ? businessNames[businessId] : null,
      businessId: businessId,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case AppRoles.client:
      return 'Client';
    case AppRoles.technician:
      return 'Technician';
    case AppRoles.owner:
      return 'Owner';
    case AppRoles.admin:
      return 'Admin';
    default:
      return role;
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({super.key, required this.user});

  final _AdminUser user;

  Future<void> _showResetAccessDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final willReactivate = !user.isActive;
    final reasonController = TextEditingController();

    final enteredReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(willReactivate ? 'Reactivate user?' : 'Deactivate user?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willReactivate
                  ? '${user.fullName} will regain access to their account.'
                  : '${user.fullName} will lose access to their account.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason (required for the audit log)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(dialogContext).pop(text);
            },
            child: Text(willReactivate ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );

    reasonController.dispose();

    if (enteredReason == null || enteredReason.isEmpty) return;
    if (!context.mounted) return;

    final adminRepository = ref.read(adminRepositoryProvider);

    try {
      await adminRepository.setUserActive(user.id, willReactivate);

      // A user with no business yet isn't "tenant data" — nothing to
      // attribute the audit entry to.
      if (user.businessId != null) {
        await adminRepository.recordAuditEntry(
          businessId: user.businessId!,
          reason: enteredReason,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willReactivate ? 'User reactivated.' : 'User deactivated.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update this user.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${_roleLabel(user.role)} · '
                    '${user.businessName ?? 'No business'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isActive ? 'Active' : 'Deactivated',
                    style: textTheme.bodySmall?.copyWith(
                      color: user.isActive
                          ? colors.success
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _showResetAccessDialog(context, ref),
              child: Text(user.isActive ? 'Deactivate' : 'Reactivate'),
            ),
          ],
        ),
      ),
    );
  }
}
