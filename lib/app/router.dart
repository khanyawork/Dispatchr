import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../features/admin/audit_log_screen.dart';
import '../features/admin/business_list_screen.dart';
import '../features/admin/platform_dashboard_screen.dart';
import '../features/admin/subscription_billing_screen.dart';
import '../features/admin/user_management_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/client/client_home_screen.dart';
import '../features/client/new_request_screen.dart';
import '../features/client/request_detail_screen.dart';
import '../features/client/request_history_screen.dart';
import '../features/technician/job_detail_screen.dart';
import '../features/owner/client_list_screen.dart';
import '../features/owner/create_edit_job_screen.dart';
import '../features/owner/dashboard_screen.dart';
import '../features/owner/job_list_screen.dart';
import '../features/owner/performance_screen.dart';
import '../features/owner/technician_roster_screen.dart';
import '../features/technician/my_jobs_screen.dart';

/// The four roles from the `profiles.role` model (README Section 8). Admin
/// is included so the guard logic below is correct from day one, even
/// though Admin has no routes yet (see [AppSession] doc comment).
enum UserRole {
  client(AppRoles.client),
  technician(AppRoles.technician),
  owner(AppRoles.owner),
  admin(AppRoles.admin);

  const UserRole(this.value);

  /// The exact string stored in `profiles.role` (README Section 10).
  final String value;

  static UserRole fromValue(String value) =>
      UserRole.values.firstWhere((role) => role.value == value);
}

/// Stand-in for the session/auth state that `lib/features/auth/auth_provider.dart`
/// will own once the auth module is built. [GoRouter]'s `redirect` needs
/// something to read auth state from and `refreshListenable` needs
/// something to listen to, so this exists to unblock routing now — replace
/// its `isAuthenticated`/`role` fields with the real Supabase-backed
/// provider when auth lands, without changing the redirect logic below.
class AppSession extends ChangeNotifier {
  AppSession._();

  static final AppSession instance = AppSession._();

  bool isAuthenticated = false;
  UserRole? role;

  void signIn(UserRole role) {
    isAuthenticated = true;
    this.role = role;
    notifyListeners();
  }

  void signOut() {
    isAuthenticated = false;
    role = null;
    notifyListeners();
  }
}

/// Path constants for every screen in README Section 8's role breakdown.
/// Section 8.4 defers the rest of the Admin *screens* to Phase 3 — only
/// `adminUsers`, `adminBilling`, and `adminAuditLog` exist so far, built
/// ahead of that guidance at explicit request (see
/// `user_management_screen.dart`'s doc comment).
abstract class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';

  static const clientHome = '/client';
  static const clientNewRequest = '/client/new-request';
  static const clientRequestDetail = '/client/requests/:id';
  static const clientHistory = '/client/history';

  static const technicianJobs = '/technician';
  static const technicianJobDetail = '/technician/jobs/:id';

  static const ownerDashboard = '/owner';
  static const ownerJobList = '/owner/jobs';
  static const ownerCreateJob = '/owner/jobs/new';
  static const ownerEditJob = '/owner/jobs/:id/edit';
  static const ownerTechnicians = '/owner/technicians';
  static const ownerClients = '/owner/clients';
  static const ownerPerformance = '/owner/performance';

  static const adminDashboard = '/admin';
  static const adminBusinesses = '/admin/businesses';
  static const adminUsers = '/admin/users';
  static const adminBilling = '/admin/billing';
  static const adminAuditLog = '/admin/audit-log';
}

/// Each role is confined to its own path prefix — a Technician can't
/// navigate into `/owner/...` and vice versa, mirroring the Permissions
/// Matrix in README Section 8.5.
String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.client:
      return AppRoutes.clientHome;
    case UserRole.technician:
      return AppRoutes.technicianJobs;
    case UserRole.owner:
      return AppRoutes.ownerDashboard;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
  }
}

String _rolePrefix(UserRole role) {
  switch (role) {
    case UserRole.client:
      return '/client';
    case UserRole.technician:
      return '/technician';
    case UserRole.owner:
      return '/owner';
    case UserRole.admin:
      return '/admin';
  }
}

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.login,
  refreshListenable: AppSession.instance,
  redirect: (context, state) {
    final session = AppSession.instance;
    final goingToAuth =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.signup;

    if (!session.isAuthenticated) {
      return goingToAuth ? null : AppRoutes.login;
    }

    if (goingToAuth) {
      return _homeForRole(session.role!);
    }

    final allowedPrefix = _rolePrefix(session.role!);
    if (!state.matchedLocation.startsWith(allowedPrefix)) {
      return _homeForRole(session.role!);
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),

    // Client (README 8.1)
    GoRoute(
      path: AppRoutes.clientHome,
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientNewRequest,
      builder: (context, state) => const NewRequestScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientRequestDetail,
      builder: (context, state) =>
          RequestDetailScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.clientHistory,
      builder: (context, state) => const RequestHistoryScreen(),
    ),

    // Technician (README 8.2)
    GoRoute(
      path: AppRoutes.technicianJobs,
      builder: (context, state) => const MyJobsScreen(),
    ),
    GoRoute(
      path: AppRoutes.technicianJobDetail,
      builder: (context, state) =>
          JobDetailScreen(jobId: state.pathParameters['id']!),
    ),

    // Owner (README 8.3)
    GoRoute(
      path: AppRoutes.ownerDashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.ownerJobList,
      builder: (context, state) => const JobListScreen(),
    ),
    GoRoute(
      path: AppRoutes.ownerCreateJob,
      builder: (context, state) => const CreateEditJobScreen(),
    ),
    GoRoute(
      path: AppRoutes.ownerEditJob,
      builder: (context, state) =>
          CreateEditJobScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.ownerTechnicians,
      builder: (context, state) => const TechnicianRosterScreen(),
    ),
    GoRoute(
      path: AppRoutes.ownerClients,
      builder: (context, state) => const ClientListScreen(),
    ),
    GoRoute(
      path: AppRoutes.ownerPerformance,
      builder: (context, state) => const PerformanceScreen(),
    ),

    // Admin (README 8.4) — built ahead of the Phase 3 deferral at
    // explicit request.
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (context, state) => const PlatformDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminBusinesses,
      builder: (context, state) => const BusinessListScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminUsers,
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminBilling,
      builder: (context, state) => const SubscriptionBillingScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminAuditLog,
      builder: (context, state) => const AuditLogScreen(),
    ),
  ],
  errorBuilder: (context, state) => const _PlaceholderScreen('Not Found'),
);

/// Stands in for the real screens (login_screen.dart, dashboard_screen.dart,
/// etc. per FileManifest.md) until each feature module is built.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );
  }
}
