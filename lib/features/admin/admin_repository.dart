import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';
import '../../dev/preview_data.dart';
import '../../dev/preview_mode.dart';
import '../../dev/preview_repositories.dart';

/// A `businesses` row as returned by Supabase.
typedef BusinessRecord = Map<String, dynamic>;

/// A `jobs` row, as embedded in [BusinessDetail.recentJobs].
typedef JobRecord = Map<String, dynamic>;

/// The read-oriented tenant view `business_detail_screen.dart` renders,
/// assembled from a business row plus the aggregate counts and recent
/// activity an Administrator needs for support purposes (README 8.4).
class BusinessDetail {
  const BusinessDetail({
    required this.business,
    required this.ownerName,
    required this.technicianCount,
    required this.jobCount,
    required this.recentJobs,
  });

  final BusinessRecord business;
  final String? ownerName;
  final int technicianCount;
  final int jobCount;
  final List<JobRecord> recentJobs;
}

/// Platform-wide counters for `platform_dashboard_screen.dart` (README
/// 8.4: "total active businesses, total users by role, platform-wide job
/// volume").
class PlatformMetrics {
  const PlatformMetrics({
    required this.totalBusinesses,
    required this.totalJobs,
    required this.jobsLast7Days,
    required this.usersByRole,
  });

  final int totalBusinesses;
  final int totalJobs;
  final int jobsLast7Days;
  final Map<String, int> usersByRole;
}

/// Cross-tenant Supabase queries for the Admin role (README Section 8.4),
/// consolidating what `user_management_screen.dart`,
/// `subscription_billing_screen.dart`, and `audit_log_screen.dart` were
/// previously each calling Supabase for directly.
class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  /// Live stream of every profile across every business tenant. Scoped by
  /// RLS's "Admins can view all profiles" policy, not a query filter.
  Stream<List<Map<String, dynamic>>> watchAllProfiles() {
    return _client.from(SupabaseTables.profiles).stream(primaryKey: ['id']);
  }

  /// Live stream of every business tenant on the platform. Scoped by
  /// RLS's "Admins can view all businesses" policy.
  Stream<List<BusinessRecord>> watchAllBusinesses() {
    return _client.from(SupabaseTables.businesses).stream(primaryKey: ['id']);
  }

  /// Live stream of every job across every business tenant, scoped by
  /// RLS's "Admins may read across businesses" policy (README Section 10).
  Stream<List<JobRecord>> watchAllJobs() {
    return _client.from(SupabaseTables.jobs).stream(primaryKey: ['id']);
  }

  /// Live stream of the full cross-tenant audit trail.
  Stream<List<Map<String, dynamic>>> watchAuditLog() {
    return _client
        .from(SupabaseTables.adminAuditLog)
        .stream(primaryKey: ['id']);
  }

  /// Sets a user's active/deactivated flag (README Section 8.4:
  /// "resetting a locked-out ... user's access").
  Future<void> setUserActive(String userId, bool isActive) {
    return _client
        .from(SupabaseTables.profiles)
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  /// Updates a business's manually-tracked plan/billing fields
  /// (README Section 8.4 "Subscription & billing overview").
  Future<void> updateBusinessBilling(
    String businessId, {
    required String planTier,
    required String billingStatus,
  }) {
    return _client
        .from(SupabaseTables.businesses)
        .update({'plan_tier': planTier, 'billing_status': billingStatus})
        .eq('id', businessId);
  }

  /// Records a cross-tenant action in `admin_audit_log` (README Section
  /// 8.4: "every access is logged with timestamp and reason, never
  /// silent").
  Future<void> recordAuditEntry({
    required String businessId,
    required String reason,
  }) {
    final adminId = _client.auth.currentUser!.id;
    return _client.from(SupabaseTables.adminAuditLog).insert({
      'admin_id': adminId,
      'business_id': businessId,
      'reason': reason,
    });
  }

  /// Assembles the read-oriented support view for a single tenant
  /// (README 8.4), logging the access via [recordAuditEntry] in the same
  /// call — "every access is logged ... never silent".
  Future<BusinessDetail> getBusinessDetail(
    String businessId, {
    required String reason,
  }) async {
    final business = await _client
        .from(SupabaseTables.businesses)
        .select()
        .eq('id', businessId)
        .single();

    final ownerId = business['owner_id'] as String?;
    String? ownerName;
    if (ownerId != null) {
      final owner = await _client
          .from(SupabaseTables.profiles)
          .select('full_name')
          .eq('id', ownerId)
          .maybeSingle();
      ownerName = owner?['full_name'] as String?;
    }

    final technicianRows = await _client
        .from(SupabaseTables.profiles)
        .select('id')
        .eq('business_id', businessId)
        .eq('role', AppRoles.technician);

    final jobRows = await _client
        .from(SupabaseTables.jobs)
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(5);

    final jobCountRow = await _client
        .from(SupabaseTables.jobs)
        .select('id')
        .eq('business_id', businessId);

    await recordAuditEntry(businessId: businessId, reason: reason);

    return BusinessDetail(
      business: business,
      ownerName: ownerName,
      technicianCount: (technicianRows as List).length,
      jobCount: (jobCountRow as List).length,
      recentJobs: List<JobRecord>.from(jobRows as List),
    );
  }

  /// Suspends a business tenant (README 8.4: "for non-payment").
  Future<void> suspendBusiness(String businessId) {
    return _client
        .from(SupabaseTables.businesses)
        .update({'status': 'suspended'})
        .eq('id', businessId);
  }

  /// Reactivates a previously-suspended business tenant.
  Future<void> reactivateBusiness(String businessId) {
    return _client
        .from(SupabaseTables.businesses)
        .update({'status': 'active'})
        .eq('id', businessId);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (PreviewMode.enabled) return PreviewAdminRepository();
  return AdminRepository(ref.watch(supabaseClientProvider));
});

/// Business list enriched with each business's owner name — a client-side
/// join since Supabase's realtime `.stream()` can't embed a foreign-key
/// select (README 8.4's Business list screen).
final businessListProvider = StreamProvider.autoDispose<List<BusinessRecord>>((
  ref,
) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchAllBusinesses().asyncMap((businesses) async {
    if (PreviewMode.enabled) {
      final profiles = PreviewStore.instance.profiles;
      return businesses
          .map(
            (b) => {
              ...b,
              'owner_name': profiles.firstWhere(
                (p) => p['id'] == b['owner_id'],
                orElse: () => const {},
              )['full_name'],
            },
          )
          .toList();
    }
    return businesses;
  });
});

final platformMetricsProvider = StreamProvider.autoDispose<PlatformMetrics>((
  ref,
) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchAllBusinesses().asyncMap((businesses) async {
    final profiles = await repo.watchAllProfiles().first;
    final jobs = await repo.watchAllJobs().first;

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final usersByRole = <String, int>{};
    for (final role in AppRoles.values) {
      usersByRole[role] = profiles.where((p) => p['role'] == role).length;
    }

    return PlatformMetrics(
      totalBusinesses: businesses.length,
      totalJobs: jobs.length,
      jobsLast7Days: jobs.where((j) {
        final createdAt = j['created_at'] as String?;
        if (createdAt == null) return false;
        final date = DateTime.tryParse(createdAt);
        return date != null && date.isAfter(sevenDaysAgo);
      }).length,
      usersByRole: usersByRole,
    );
  });
});
