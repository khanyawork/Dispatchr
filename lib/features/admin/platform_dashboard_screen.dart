import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../shared/widgets/section_nav_menu.dart';
import 'admin_repository.dart';
import 'business_list_screen.dart';

/// Platform-wide dashboard: total businesses, users by role, job volume,
/// system health (README 8.4). `FileManifest.md`:
/// `lib/features/admin/platform_dashboard_screen.dart`.
class PlatformDashboardScreen extends ConsumerWidget {
  const PlatformDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(platformMetricsProvider);
    final isDark = context.isDarkMode;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Businesses',
            onPressed: () => context.push(const BusinessListScreen()),
          ),
          SectionNavMenu(items: adminSectionItems()),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load platform metrics',
            style: TextStyle(color: alert),
          ),
        ),
        data: (metrics) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MetricsGrid(metrics: metrics),
            const SizedBox(height: 24),
            const _SectionLabel(title: 'USERS BY ROLE'),
            const SizedBox(height: 8),
            _UsersByRoleCard(usersByRole: metrics.usersByRole),
            const SizedBox(height: 24),
            const _SectionLabel(title: 'SYSTEM HEALTH'),
            const SizedBox(height: 8),
            const _SystemHealthCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.isDarkMode
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    return Text(
      title,
      style: TextStyle(
        color: textSecondary,
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final PlatformMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        label: 'Total Businesses',
        value: metrics.totalBusinesses.toString(),
        icon: Icons.business_outlined,
      ),
      _MetricCard(
        label: 'Total Jobs',
        value: metrics.totalJobs.toString(),
        icon: Icons.assignment_outlined,
      ),
      _MetricCard(
        label: 'Jobs (Last 7 Days)',
        value: metrics.jobsLast7Days.toString(),
        icon: Icons.trending_up,
      ),
    ];

    // Command-center screens get more breathing room on a desktop window
    // (README Section 4) — lay metric cards out in a row once there's
    // space, otherwise stack them.
    if (context.isDesktop || context.isTablet) {
      return Row(
        children: [
          for (final card in cards) ...[
            Expanded(child: card),
            if (card != cards.last) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (final card in cards) ...[
          card,
          if (card != cards.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final primary = isDark
        ? DesignTokens.primaryDark
        : DesignTokens.primaryLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceAlt,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: DesignTokens.fontSizeXxl,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
          ),
        ],
      ),
    );
  }
}

class _UsersByRoleCard extends StatelessWidget {
  const _UsersByRoleCard({required this.usersByRole});

  final Map<String, int> usersByRole;

  static const Map<String, String> _labels = {
    'client': 'Clients',
    'technician': 'Technicians',
    'owner': 'Owners',
    'admin': 'Administrators',
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceAlt,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final entry in usersByRole.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _labels[entry.key] ?? entry.key,
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Static placeholder — README lists error monitoring (Sentry) as a
/// Phase 2+ recommendation (Section 4), so there's no real health signal
/// to surface yet. Swap this for a live check once monitoring is wired up.
class _SystemHealthCard extends StatelessWidget {
  const _SystemHealthCard();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final success = isDark
        ? DesignTokens.successDark
        : DesignTokens.successLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceAlt,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: success, size: 20),
          const SizedBox(width: 10),
          Text('All systems normal', style: TextStyle(color: textPrimary)),
        ],
      ),
    );
  }
}
