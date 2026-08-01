import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_nav_menu.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'admin_repository.dart';

const _planTiers = ['trial', 'starter', 'pro', 'enterprise'];
const _billingStatuses = ['active', 'past_due', 'canceled'];

/// README Section 8.4's Subscription & billing overview: plan tier per
/// business, payment status, and churn indicators, across every tenant.
///
/// NOTE: like `user_management_screen.dart`, this is one of the Admin
/// screens README Section 8.4 / FileManifest.md defer to Phase 3 — built
/// ahead of that guidance at explicit request.
///
/// There's no payment processor integration yet (README Section 12 puts
/// Stripe in Phase 3) and no billing data existed anywhere in the schema.
/// `businesses.plan_tier` / `businesses.billing_status` (added in
/// `0007_business_billing.sql`) are manually set by the Administrator for
/// now — not derived from a real subscription/payment system. Every
/// change is written to `admin_audit_log` with a required reason, same as
/// `user_management_screen.dart`.
///
class SubscriptionBillingScreen extends ConsumerWidget {
  const SubscriptionBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminRepository = ref.watch(adminRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
        actions: [SectionNavMenu(items: adminSectionItems())],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: adminRepository.watchAllBusinesses(),
        builder: (context, businessSnapshot) {
          if (businessSnapshot.hasError) {
            return const EmptyState(
              message: "Couldn't load businesses. Pull to retry.",
              icon: Icons.error_outline,
            );
          }

          if (!businessSnapshot.hasData) {
            return const SkeletonLoader();
          }

          final businesses = businessSnapshot.data!;

          if (businesses.isEmpty) {
            return const EmptyState(
              message: 'No businesses on the platform yet.',
              icon: Icons.business_outlined,
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: adminRepository.watchAllProfiles(),
            builder: (context, profileSnapshot) {
              final ownerNames = <String, String>{
                for (final row in profileSnapshot.data ?? const [])
                  row['id'] as String:
                      ((row['full_name'] as String?)?.trim().isNotEmpty ==
                          true)
                      ? row['full_name'] as String
                      : 'Unnamed owner',
              };

              final entries =
                  businesses
                      .map((row) => _BusinessBilling.fromRow(row, ownerNames))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryRow(entries: entries),
                  const SizedBox(height: 16),
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BusinessCard(
                        key: ValueKey(entry.id),
                        entry: entry,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Lightweight stand-in for the row shape until a shared business model
/// exists.
class _BusinessBilling {
  const _BusinessBilling({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.planTier,
    required this.billingStatus,
  });

  final String id;
  final String name;
  final String ownerName;
  final String planTier;
  final String billingStatus;

  factory _BusinessBilling.fromRow(
    Map<String, dynamic> row,
    Map<String, String> ownerNames,
  ) {
    final ownerId = row['owner_id'] as String?;
    return _BusinessBilling(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? 'Unnamed business',
      ownerName: ownerId != null
          ? (ownerNames[ownerId] ?? 'Unknown owner')
          : 'No owner',
      planTier: row['plan_tier'] as String? ?? 'trial',
      billingStatus: row['billing_status'] as String? ?? 'active',
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.entries});

  final List<_BusinessBilling> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final active = entries.where((e) => e.billingStatus == 'active').length;
    final pastDue = entries
        .where((e) => e.billingStatus == 'past_due')
        .length;
    final canceled = entries
        .where((e) => e.billingStatus == 'canceled')
        .length;
    final churnRate = total == 0 ? 0 : (canceled / total * 100).round();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(label: 'Total businesses', value: '$total'),
        _StatTile(label: 'Active', value: '$active'),
        _StatTile(label: 'Past due', value: '$pastDue'),
        _StatTile(label: 'Churn rate', value: '$churnRate%'),
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

class _BusinessCard extends ConsumerWidget {
  const _BusinessCard({super.key, required this.entry});

  final _BusinessBilling entry;

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    var selectedTier = entry.planTier;
    var selectedStatus = entry.billingStatus;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(entry.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedTier,
                decoration: const InputDecoration(labelText: 'Plan tier'),
                items: _planTiers
                    .map(
                      (tier) =>
                          DropdownMenuItem(value: tier, child: Text(tier)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedTier = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Billing status',
                ),
                items: _billingStatuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedStatus = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (required for the audit log)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true) return;
    if (!context.mounted) return;

    final adminRepository = ref.read(adminRepositoryProvider);

    try {
      await adminRepository.updateBusinessBilling(
        entry.id,
        planTier: selectedTier,
        billingStatus: selectedStatus,
      );

      await adminRepository.recordAuditEntry(
        businessId: entry.id,
        reason: reason,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Billing updated.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update billing.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final scheme = Theme.of(context).colorScheme;
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
                  Text(entry.name, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${entry.ownerName}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Chip(label: entry.planTier, color: colors.textSecondary),
                      _Chip(
                        label: entry.billingStatus.replaceAll('_', ' '),
                        color: _statusColor(entry.billingStatus, colors, scheme),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit billing',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(
  String status,
  AppColorExtension colors,
  ColorScheme scheme,
) {
  switch (status) {
    case 'active':
      return colors.success;
    // README Section 5.1: red is reserved for urgent/overdue flags — a
    // past-due payment is exactly that.
    case 'past_due':
      return scheme.error;
    default:
      return colors.textSecondary;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
