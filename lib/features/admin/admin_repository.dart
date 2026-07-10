import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef BusinessRecord = Map<String, dynamic>;
typedef JobRecord = Map<String, dynamic>;

/// Platform-wide counts for `platform_dashboard_screen.dart` (README 8.4:
/// "total active businesses, total users by role, platform-wide job
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

/// A single tenant's read-oriented support view (README 8.4: "Business
/// detail view"). Every load is preceded by an `admin_audit_log` write —
/// see [AdminRepository.getBusinessDetail].
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

class AdminRepositoryException implements Exception {
  AdminRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cross-tenant Supabase queries (`FileManifest.md`:
/// `lib/features/admin/admin_repository.dart`). Unlike the client/
/// technician/owner repositories, these queries intentionally read across
/// every business — that's the Administrator's whole purpose (README
/// Section 8.4) — so every per-tenant read is paired with a write to
/// `admin_audit_log` (README Section 10): "every access is logged with
/// timestamp and reason, never silent." Aggregate-only reads (platform
/// metrics, the business list) are NOT individually audited — README 8.4
/// distinguishes "aggregate, cross-tenant metrics" from "individual
/// tenant data," and only the latter requires a logged reason.
///
/// `businesses.status` (`active`/`suspended`) referenced below extends
/// the illustrative schema in README Section 10 to support "suspend,
/// reactivate, or offboard a business tenant" (Section 8.4) — add it via
/// a migration before wiring this up against a real database. RLS
/// policies allowing an admin to read `businesses`/`profiles` across
/// tenants aren't shown in README Section 10 either (only the `jobs`
/// policy is); mirror that same "admin may read across businesses"
/// pattern onto those two tables before relying on this in production.
class AdminRepository {
  AdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const List<String> _roles = [
    'client',
    'technician',
    'owner',
    'admin',
  ];

  String get _requireAdminId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
        'AdminRepository requires an authenticated administrator',
      );
    }
    return id;
  }

  /// Aggregate, cross-tenant metrics for the platform dashboard.
  Future<PlatformMetrics> getPlatformMetrics() async {
    final businessCountResponse = await _client
        .from('businesses')
        .select('id')
        .count(CountOption.exact);
    final jobCountResponse = await _client
        .from('jobs')
        .select('id')
        .count(CountOption.exact);

    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final recentJobCountResponse = await _client
        .from('jobs')
        .select('id')
        .gte('created_at', sevenDaysAgo)
        .count(CountOption.exact);

    final usersByRole = <String, int>{};
    for (final role in _roles) {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('role', role)
          .count(CountOption.exact);
      usersByRole[role] = response.count;
    }

    return PlatformMetrics(
      totalBusinesses: businessCountResponse.count,
      totalJobs: jobCountResponse.count,
      jobsLast7Days: recentJobCountResponse.count,
      usersByRole: usersByRole,
    );
  }

  /// Every business on the platform (README 8.4 "Business (tenant)
  /// list"), with each owner's name resolved separately —
  /// `businesses.owner_id` references `auth.users`, not `profiles`, so
  /// PostgREST can't auto-embed it the way `jobs.assigned_technician_id`
  /// embeds a technician's profile.
  Future<List<BusinessRecord>> listBusinesses() async {
    final businesses = await _client
        .from('businesses')
        .select()
        .order('created_at', ascending: false);
    final rows = List<BusinessRecord>.from(businesses);

    final ownerIds = rows
        .map((b) => b['owner_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (ownerIds.isEmpty) return rows;

    final owners = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', ownerIds);
    final ownerNames = {
      for (final owner in List<Map<String, dynamic>>.from(owners))
        owner['id'] as String: owner['full_name'] as String?,
    };

    return [
      for (final business in rows)
        {...business, 'owner_name': ownerNames[business['owner_id']]},
    ];
  }

  Future<void> suspendBusiness(String businessId) {
    return _client
        .from('businesses')
        .update({'status': 'suspended'})
        .eq('id', businessId);
  }

  Future<void> reactivateBusiness(String businessId) {
    return _client
        .from('businesses')
        .update({'status': 'active'})
        .eq('id', businessId);
  }

  /// Loads a specific tenant's support view. [reason] is required and
  /// logged to `admin_audit_log` before any tenant data is read (README
  /// 8.4). Call this exactly once per deliberate access — e.g. after a
  /// confirmation dialog in `initState` — rather than from a reactively
  /// re-evaluated provider, so the audit trail reflects real look-ins
  /// rather than incidental rebuilds.
  Future<BusinessDetail> getBusinessDetail(
    String businessId, {
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw AdminRepositoryException(
        'A reason is required to view tenant data',
      );
    }

    await _client.from('admin_audit_log').insert({
      'admin_id': _requireAdminId,
      'business_id': businessId,
      'reason': trimmedReason,
    });

    final business = await _client
        .from('businesses')
        .select()
        .eq('id', businessId)
        .single();

    final ownerId = business['owner_id'] as String?;
    String? ownerName;
    if (ownerId != null) {
      final owner = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', ownerId)
          .maybeSingle();
      ownerName = owner?['full_name'] as String?;
    }

    final technicianCountResponse = await _client
        .from('profiles')
        .select('id')
        .eq('business_id', businessId)
        .eq('role', 'technician')
        .count(CountOption.exact);

    final jobCountResponse = await _client
        .from('jobs')
        .select('id')
        .eq('business_id', businessId)
        .count(CountOption.exact);

    final recentJobs = await _client
        .from('jobs')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(10);

    return BusinessDetail(
      business: business,
      ownerName: ownerName,
      technicianCount: technicianCountResponse.count,
      jobCount: jobCountResponse.count,
      recentJobs: List<JobRecord>.from(recentJobs),
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final platformMetricsProvider = FutureProvider.autoDispose<PlatformMetrics>((
  ref,
) {
  return ref.watch(adminRepositoryProvider).getPlatformMetrics();
});

final businessListProvider = FutureProvider.autoDispose<List<BusinessRecord>>((
  ref,
) {
  return ref.watch(adminRepositoryProvider).listBusinesses();
});
