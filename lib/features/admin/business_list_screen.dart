import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import 'admin_repository.dart';
import 'business_detail_screen.dart';

/// Every business on the platform (README 8.4). `FileManifest.md`:
/// `lib/features/admin/business_list_screen.dart`.
///
/// Subscription/billing status isn't shown here — README's own roadmap
/// (Section 12) places billing in Phase 2, and no `businesses` column for
/// it exists yet (unlike `status`, which this screen does use for
/// suspend/reactivate — a Phase 1 capability per Section 8.4).
class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(businessListProvider);
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Businesses')),
      body: businessesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load businesses', style: TextStyle(color: alert)),
        ),
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Text('No businesses onboarded yet', style: TextStyle(color: textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(businessListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BusinessRow(business: businesses[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BusinessRow extends StatelessWidget {
  const _BusinessRow({required this.business});

  final BusinessRecord business;

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
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;

    final isActive = (business['status'] as String? ?? 'active') == 'active';
    final createdAt = business['created_at'] != null
        ? DateTime.tryParse(business['created_at'] as String)
        : null;

    return Material(
      color: surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(BusinessDetailScreen(businessId: business['id'] as String)),
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
                      business['name'] as String? ?? 'Unnamed business',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Owner: ${business['owner_name'] ?? 'Unknown'}',
                      style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
                    ),
                    if (createdAt != null)
                      Text(
                        'Joined ${DateFormatter.formatDate(createdAt)}',
                        style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeXs),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? success : alert).withValues(alpha: 0.12),
                  border: Border.all(color: isActive ? success : alert),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                    color: isActive ? success : alert,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeXs,
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
