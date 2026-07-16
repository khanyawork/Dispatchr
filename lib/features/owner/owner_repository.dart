import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';
import '../../dev/preview_mode.dart';
import '../../dev/preview_repositories.dart';

/// A `jobs` row as returned by Supabase (business-scoped, Owner view).
typedef JobRecord = Map<String, dynamic>;

/// A `profiles` row for a technician on the Owner's roster.
typedef TechnicianRecord = Map<String, dynamic>;

/// Filters for the Owner's "All Jobs" list (README 8.3: "filterable by
/// date range, technician, and status").
typedef JobListFilter = ({
  DateTime? fromDate,
  DateTime? toDate,
  String? technicianId,
  String? status,
  String? clientId,
});

String _dateToPostgres(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _timeToPostgres(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

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
  Stream<List<JobRecord>> watchBusinessJobs(String businessId) {
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

  /// Creates a new job already assigned/scheduled by the Owner (README
  /// 8.3: "Create, edit, and delete jobs; assign or reassign any job").
  /// Always starts `pending`, per the `jobs.status` default.
  Future<String> createJob({
    required String clientName,
    required String address,
    String? description,
    String? assignedTechnicianId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    final businessId = await fetchOwnBusinessId();
    final row = await _client
        .from(SupabaseTables.jobs)
        .insert({
          'business_id': businessId,
          'client_name': clientName,
          'address': address,
          'description': description,
          'assigned_technician_id': assignedTechnicianId,
          'scheduled_date': scheduledDate == null
              ? null
              : _dateToPostgres(scheduledDate),
          'scheduled_time': scheduledTime == null
              ? null
              : _timeToPostgres(scheduledTime),
          'status': JobStatuses.pending,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Edits an existing job, including a manual [status] override (README
  /// 8.3: "Override job status manually ... logged for audit purposes").
  Future<void> updateJob(
    String jobId, {
    required String clientName,
    required String address,
    String? description,
    String? assignedTechnicianId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    required String status,
  }) {
    return _client
        .from(SupabaseTables.jobs)
        .update({
          'client_name': clientName,
          'address': address,
          'description': description,
          'assigned_technician_id': assignedTechnicianId,
          'scheduled_date': scheduledDate == null
              ? null
              : _dateToPostgres(scheduledDate),
          'scheduled_time': scheduledTime == null
              ? null
              : _timeToPostgres(scheduledTime),
          'status': status,
        })
        .eq('id', jobId);
  }

  /// Deletes a job outright (README 8.3: "Create, edit, and delete jobs").
  Future<void> deleteJob(String jobId) {
    return _client.from(SupabaseTables.jobs).delete().eq('id', jobId);
  }
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  if (PreviewMode.enabled) return PreviewOwnerRepository();
  return OwnerRepository(ref.watch(supabaseClientProvider));
});

/// The signed-in Owner's business id — every dashboard/list/form provider
/// below builds on this rather than re-deriving it.
final ownerBusinessIdProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(ownerRepositoryProvider).fetchOwnBusinessId();
});

bool _isOverdue(String? scheduledDate, String? status) {
  if (scheduledDate == null || status == JobStatuses.completed) return false;
  final date = DateTime.tryParse(scheduledDate);
  if (date == null) return false;
  final today = DateTime.now();
  final todayAtMidnight = DateTime(today.year, today.month, today.day);
  return date.isBefore(todayAtMidnight);
}

/// Jobs that need the Owner's attention: unassigned, or scheduled for a
/// day that's already passed without being completed (README 5.1: red for
/// "overdue/unassigned job flags").
final dashboardAlertsProvider = StreamProvider.autoDispose<List<JobRecord>>((
  ref,
) async* {
  final businessId = await ref.watch(ownerBusinessIdProvider.future);
  if (businessId == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(ownerRepositoryProvider)
      .watchBusinessJobs(businessId)
      .map(
        (jobs) => jobs.where((job) {
          final status = job['status'] as String?;
          final unassigned = job['assigned_technician_id'] == null;
          final overdue = _isOverdue(job['scheduled_date'] as String?, status);
          return status != JobStatuses.completed && (unassigned || overdue);
        }).toList(),
      );
});

/// Today's jobs across the business, for the dashboard's main feed.
final todaysJobsProvider = StreamProvider.autoDispose<List<JobRecord>>((
  ref,
) async* {
  final businessId = await ref.watch(ownerBusinessIdProvider.future);
  if (businessId == null) {
    yield const [];
    return;
  }
  final today = _dateToPostgres(DateTime.now());
  yield* ref
      .watch(ownerRepositoryProvider)
      .watchBusinessJobs(businessId)
      .map((jobs) => jobs.where((j) => j['scheduled_date'] == today).toList());
});

/// The full technician roster for the business (README 8.3).
final technicianRosterProvider =
    StreamProvider.autoDispose<List<TechnicianRecord>>((ref) async* {
      final businessId = await ref.watch(ownerBusinessIdProvider.future);
      if (businessId == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(ownerRepositoryProvider)
          .watchBusinessProfiles(businessId)
          .map(
            (rows) =>
                rows.where((r) => r['role'] == AppRoles.technician).toList(),
          );
    });

bool _matchesFilter(JobRecord job, JobListFilter filter) {
  if (filter.status != null && job['status'] != filter.status) return false;
  if (filter.technicianId != null &&
      job['assigned_technician_id'] != filter.technicianId) {
    return false;
  }
  if (filter.clientId != null && job['client_id'] != filter.clientId) {
    return false;
  }
  final rawDate = job['scheduled_date'] as String?;
  final date = rawDate == null ? null : DateTime.tryParse(rawDate);
  if (filter.fromDate != null &&
      (date == null || date.isBefore(filter.fromDate!))) {
    return false;
  }
  if (filter.toDate != null &&
      (date == null || date.isAfter(filter.toDate!))) {
    return false;
  }
  return true;
}

/// The Owner's "All Jobs" list, filtered client-side by [JobListFilter]
/// (README 8.3: "filterable by date range, technician, status, client").
final jobListProvider = StreamProvider.autoDispose
    .family<List<JobRecord>, JobListFilter>((ref, filter) async* {
      final businessId = await ref.watch(ownerBusinessIdProvider.future);
      if (businessId == null) {
        yield const [];
        return;
      }
      yield* ref
          .watch(ownerRepositoryProvider)
          .watchBusinessJobs(businessId)
          .map((jobs) => jobs.where((j) => _matchesFilter(j, filter)).toList());
    });

/// A single job by id, scoped to the Owner's own business — backs
/// `create_edit_job_screen.dart`'s prefill when editing.
final jobByIdProvider = StreamProvider.autoDispose.family<JobRecord?, String>((
  ref,
  jobId,
) async* {
  final businessId = await ref.watch(ownerBusinessIdProvider.future);
  if (businessId == null) {
    yield null;
    return;
  }
  yield* ref
      .watch(ownerRepositoryProvider)
      .watchBusinessJobs(businessId)
      .map(
        (jobs) => jobs
            .cast<JobRecord?>()
            .firstWhere((j) => j!['id'] == jobId, orElse: () => null),
      );
});
