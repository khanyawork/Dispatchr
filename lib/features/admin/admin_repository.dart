import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';

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
  Stream<List<Map<String, dynamic>>> watchAllBusinesses() {
    return _client.from(SupabaseTables.businesses).stream(primaryKey: ['id']);
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
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});
