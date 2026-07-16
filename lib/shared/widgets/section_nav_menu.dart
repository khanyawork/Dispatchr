import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// One entry in a [SectionNavMenu] — a sibling command-center section this
/// role can jump to directly.
class SectionNavItem {
  const SectionNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

/// Compact "switch section" menu for the Owner/Admin command-center screens
/// (README 8.3/8.4 list several sibling screens per role — Dashboard, Job
/// List, Technicians, Clients, Performance for Owner; Platform Dashboard,
/// Businesses, Users, Billing, Audit Log for Admin). Each of those screens
/// is its own top-level `go_router` route reached only by direct URL today;
/// this menu — dropped into any screen's `AppBar.actions` — makes every
/// sibling section reachable in one tap without restructuring the screen's
/// existing `Scaffold`. Always ends with "Log out".
class SectionNavMenu extends StatelessWidget {
  const SectionNavMenu({super.key, required this.items});

  final List<SectionNavItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Switch section',
      icon: const Icon(Icons.apps_rounded),
      onSelected: (route) {
        if (route == '_logout') {
          AppSession.instance.signOut();
        } else {
          context.go(route);
        }
      },
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item.route,
            child: Row(
              children: [
                Icon(item.icon, size: 20),
                const SizedBox(width: 12),
                Text(item.label),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: '_logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Log out'),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Owner's five command-center sections (README 8.3).
List<SectionNavItem> ownerSectionItems() => const [
  SectionNavItem(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    route: AppRoutes.ownerDashboard,
  ),
  SectionNavItem(
    icon: Icons.list_alt_outlined,
    label: 'All Jobs',
    route: AppRoutes.ownerJobList,
  ),
  SectionNavItem(
    icon: Icons.groups_outlined,
    label: 'Technicians',
    route: AppRoutes.ownerTechnicians,
  ),
  SectionNavItem(
    icon: Icons.people_alt_outlined,
    label: 'Clients',
    route: AppRoutes.ownerClients,
  ),
  SectionNavItem(
    icon: Icons.insights_outlined,
    label: 'Performance',
    route: AppRoutes.ownerPerformance,
  ),
];

/// The Administrator's platform-level sections (README 8.4).
List<SectionNavItem> adminSectionItems() => const [
  SectionNavItem(
    icon: Icons.dashboard_outlined,
    label: 'Platform Dashboard',
    route: AppRoutes.adminDashboard,
  ),
  SectionNavItem(
    icon: Icons.business_outlined,
    label: 'Businesses',
    route: AppRoutes.adminBusinesses,
  ),
  SectionNavItem(
    icon: Icons.manage_accounts_outlined,
    label: 'User Management',
    route: AppRoutes.adminUsers,
  ),
  SectionNavItem(
    icon: Icons.receipt_long_outlined,
    label: 'Subscription & Billing',
    route: AppRoutes.adminBilling,
  ),
  SectionNavItem(
    icon: Icons.fact_check_outlined,
    label: 'Audit Log',
    route: AppRoutes.adminAuditLog,
  ),
];
