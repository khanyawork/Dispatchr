import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';

/// Business-scoped Supabase queries for the Owner role (README Section
/// 8.3), consolidating what `technician_roster_screen.dart`,
/// `client_list_screen.dart`, and `performance_screen.dart` were
/// previously each calling Supabase for directly.
class OwnerRepository {
  const OwnerRepository(this._client);

  final SupabaseClient _client;

  /// The signed-in Owner's own `profiles.business_id`. Null if their
  /// account somehow has no business yet.
  Future<String?> fetchOwnBusinessId() async {
    final userId = _client.auth.currentUser!.id;
    final profile = await _client
        .from(SupabaseTables.profiles)
        .select('business_id')
        .eq('id', userId)
        .single();
    return profile['business_id'] as String?;
  }

  /// Live stream of every job in [businessId] — the shared source data
  /// behind the client list, technician roster, and performance screens.
  Stream<List<Map<String, dynamic>>> watchBusinessJobs(String businessId) {
    return _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId);
  }

  /// Live stream of every profile linked to [businessId] (the Owner
  /// themselves, technicians, and any client whose profile happens to
  /// carry this business_id). Callers filter by `role` for the subset
  /// they need.
  Stream<List<Map<String, dynamic>>> watchBusinessProfiles(
    String businessId,
  ) {
    return _client
        .from(SupabaseTables.profiles)
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId);
  }

  /// Sets a technician's active/deactivated flag
  /// (README Section 8.3 "invite, deactivate").
  Future<void> setTechnicianActive(String technicianId, bool isActive) {
    return _client
        .from(SupabaseTables.profiles)
        .update({'is_active': isActive})
        .eq('id', technicianId);
  }

  /// Technicians who have registered but aren't linked to any business yet
  /// — the pool `technician_roster_screen.dart`'s "Add technician" sheet
  /// picks from, standing in for README's "invite" capability until a
  /// real email-invite flow exists.
  Future<List<Map<String, dynamic>>> fetchUnassignedTechnicians() {
    return _client
        .from(SupabaseTables.profiles)
        .select('id, full_name')
        .eq('role', AppRoles.technician)
        .isFilter('business_id', null);
  }

  /// Links a previously-unassigned technician into [businessId].
  Future<void> assignTechnicianToBusiness(
    String technicianId,
    String businessId,
  ) {
    return _client
        .from(SupabaseTables.profiles)
        .update({'business_id': businessId})
        .eq('id', technicianId);
  }
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository(ref.watch(supabaseClientProvider));
});
