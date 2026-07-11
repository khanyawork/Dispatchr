import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';

/// Thin wrapper around Supabase Realtime's `.stream()` builder — the single
/// place that constructs the live `postgres_changes` subscriptions behind
/// job status updates (README Section 8.2's live "My Jobs" list, Section
/// 8.3's live business dashboard). `job_repository.dart` and
/// `owner_repository.dart` build their job/profile streams on top of this
/// rather than each hand-rolling `_client.from(...).stream(primaryKey: ['id'])`.
class RealtimeService {
  const RealtimeService(this._client);

  final SupabaseClient _client;

  /// Live rows from the `jobs` table where [column] equals [value],
  /// optionally ordered by [orderBy]. Backs `watchClientJobs` (column
  /// `client_id`), `watchTechnicianJobs` (column `assigned_technician_id`),
  /// and `watchBusinessJobs` (column `business_id`).
  Stream<List<Map<String, dynamic>>> watchJobsWhere({
    required String column,
    required Object value,
    String? orderBy,
    bool ascending = true,
  }) {
    final stream = _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq(column, value);
    return orderBy == null
        ? stream
        : stream.order(orderBy, ascending: ascending);
  }

  /// A single job by [jobId], or null if it doesn't exist / isn't visible
  /// to the caller under RLS (`job_detail_screen.dart`'s live status).
  Stream<Map<String, dynamic>?> watchJob(String jobId) {
    return _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Live rows from [table] where [column] equals [value] — generalizes
  /// the job-specific helpers above for other live lists (e.g. Owner's
  /// `watchBusinessProfiles`).
  Stream<List<Map<String, dynamic>>> watchTableWhere({
    required String table,
    required String column,
    required Object value,
  }) {
    return _client.from(table).stream(primaryKey: ['id']).eq(column, value);
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref.watch(supabaseClientProvider));
});
