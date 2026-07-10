import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/date_formatter.dart';

/// A `jobs` row as returned by Supabase.
typedef JobRecord = Map<String, dynamic>;

/// A `profiles` row for a technician in the owner's business.
typedef TechnicianRecord = Map<String, dynamic>;

/// Filters for `job_list_screen.dart` (README 8.3: "filterable by date
/// range, technician, status, client"). A record gets structural equality
/// for free, which is what Riverpod's `.family` needs to cache correctly.
typedef JobListFilter = ({
  DateTime? fromDate,
  DateTime? toDate,
  String? technicianId,
  String? status,
  String? clientId,
});

const JobListFilter emptyJobListFilter = (
  fromDate: null,
  toDate: null,
  technicianId: null,
  status: null,
  clientId: null,
);

class OwnerRepositoryException implements Exception {
  OwnerRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Business-scoped Supabase queries (`FileManifest.md`:
/// `lib/features/owner/owner_repository.dart`). Every query is scoped to
/// the owner's own `business_id` (README Section 8.3: "Full data for their
/// own business tenant"), mirroring the `jobs`/`profiles` RLS policies in
/// README Section 10 — the filters below are defense in depth, not the
/// sole guard.
class OwnerRepository {
  OwnerRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _selectWithTechnician =
      '*, technician:profiles!assigned_technician_id(full_name)';

  String get _requireOwnerId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('OwnerRepository requires an authenticated owner');
    }
    return id;
  }

  Future<String> _requireBusinessId() async {
    final row = await _client
        .from('profiles')
        .select('business_id')
        .eq('id', _requireOwnerId)
        .single();
    final businessId = row['business_id'] as String?;
    if (businessId == null) {
      throw OwnerRepositoryException('Owner profile has no business assigned');
    }
    return businessId;
  }

  static String _dateToPostgres(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _timeToPostgres(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  // ---------------------------------------------------------------------
  // Dashboard (dashboard_screen.dart)
  // ---------------------------------------------------------------------

  /// Live "today at a glance" jobs. `.stream()` only supports a single
  /// `.eq()` filter, so `business_id` is applied server-side and the "is
  /// today" check is applied client-side via [Stream.map].
  Stream<List<JobRecord>> watchTodaysJobs() async* {
    final businessId = await _requireBusinessId();
    final today = _dateToPostgres(DateTime.now());
    yield* _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('scheduled_time')
        .map(
          (rows) =>
              rows.where((row) => row['scheduled_date'] == today).toList(),
        );
  }

  /// Overdue (past-due, not completed) or unassigned jobs — flagged red on
  /// the dashboard per README Section 5.1.
  Stream<List<JobRecord>> watchAlerts() async* {
    final businessId = await _requireBusinessId();
    yield* _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('scheduled_date')
        .map(
          (rows) => rows.where((row) {
            if (row['status'] == 'completed') return false;
            final rawDate = row['scheduled_date'] as String?;
            final scheduledDate = rawDate == null
                ? null
                : DateTime.tryParse(rawDate);
            final isOverdue =
                scheduledDate != null && DateFormatter.isPastDay(scheduledDate);
            final isUnassigned = row['assigned_technician_id'] == null;
            return isOverdue || isUnassigned;
          }).toList(),
        );
  }

  /// Live technician roster for the dashboard's status panel and the
  /// create/edit job form's assignment dropdown.
  Stream<List<TechnicianRecord>> watchTechnicianRoster() async* {
    final businessId = await _requireBusinessId();
    yield* _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('full_name')
        .map((rows) => rows.where((row) => row['role'] == 'technician').toList());
  }

  // ---------------------------------------------------------------------
  // Job list (job_list_screen.dart)
  // ---------------------------------------------------------------------

  /// A plain (non-realtime) filtered fetch — the regular Postgrest query
  /// builder supports chaining multiple filters, unlike `.stream()`.
  Future<List<JobRecord>> listJobs(JobListFilter filter) async {
    final businessId = await _requireBusinessId();
    var query = _client
        .from('jobs')
        .select(_selectWithTechnician)
        .eq('business_id', businessId);

    if (filter.fromDate != null) {
      query = query.gte('scheduled_date', _dateToPostgres(filter.fromDate!));
    }
    if (filter.toDate != null) {
      query = query.lte('scheduled_date', _dateToPostgres(filter.toDate!));
    }
    if (filter.technicianId != null) {
      query = query.eq('assigned_technician_id', filter.technicianId!);
    }
    if (filter.status != null) {
      query = query.eq('status', filter.status!);
    }
    if (filter.clientId != null) {
      query = query.eq('client_id', filter.clientId!);
    }

    final rows = await query
        .order('scheduled_date', ascending: false)
        .order('scheduled_time', ascending: false);
    return List<JobRecord>.from(rows);
  }

  // ---------------------------------------------------------------------
  // Job creation / edit (create_edit_job_screen.dart)
  // ---------------------------------------------------------------------

  Future<JobRecord?> getJobById(String jobId) async {
    final businessId = await _requireBusinessId();
    final rows = await _client
        .from('jobs')
        .select(_selectWithTechnician)
        .eq('id', jobId)
        .eq('business_id', businessId)
        .limit(1);
    final list = List<JobRecord>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  Future<JobRecord> createJob({
    required String clientName,
    required String address,
    String? description,
    String? clientId,
    String? assignedTechnicianId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    final businessId = await _requireBusinessId();
    return _client
        .from('jobs')
        .insert({
          'business_id': businessId,
          'client_id': clientId,
          'assigned_technician_id': assignedTechnicianId,
          'client_name': clientName,
          'address': address,
          'description': description,
          'scheduled_date': scheduledDate == null
              ? null
              : _dateToPostgres(scheduledDate),
          'scheduled_time': scheduledTime == null
              ? null
              : _timeToPostgres(scheduledTime),
        })
        .select(_selectWithTechnician)
        .single();
  }

  /// Updates only the fields passed in — `null` means "leave unchanged",
  /// so callers don't need to resend the entire job. Also used for the
  /// owner's manual status override (README 8.3: "Override job status
  /// manually... logged for audit purposes" — an `audit_log` write should
  /// be added here once a job-status audit table exists; only
  /// `admin_audit_log` is defined in README Section 10 today, and that
  /// covers cross-tenant admin reads, not owner overrides).
  Future<JobRecord> updateJob(
    String jobId, {
    String? clientName,
    String? address,
    String? description,
    String? assignedTechnicianId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    String? status,
  }) async {
    final businessId = await _requireBusinessId();
    final updates = <String, dynamic>{
      if (clientName != null) 'client_name': clientName,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
      if (assignedTechnicianId != null)
        'assigned_technician_id': assignedTechnicianId,
      if (scheduledDate != null)
        'scheduled_date': _dateToPostgres(scheduledDate),
      if (scheduledTime != null)
        'scheduled_time': _timeToPostgres(scheduledTime),
      if (status != null) 'status': status,
    };

    return _client
        .from('jobs')
        .update(updates)
        .eq('id', jobId)
        .eq('business_id', businessId)
        .select(_selectWithTechnician)
        .single();
  }

  Future<void> deleteJob(String jobId) async {
    final businessId = await _requireBusinessId();
    await _client
        .from('jobs')
        .delete()
        .eq('id', jobId)
        .eq('business_id', businessId);
  }
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository();
});

final todaysJobsProvider = StreamProvider.autoDispose<List<JobRecord>>((ref) {
  return ref.watch(ownerRepositoryProvider).watchTodaysJobs();
});

final dashboardAlertsProvider = StreamProvider.autoDispose<List<JobRecord>>((
  ref,
) {
  return ref.watch(ownerRepositoryProvider).watchAlerts();
});

final technicianRosterProvider = StreamProvider.autoDispose<List<TechnicianRecord>>((
  ref,
) {
  return ref.watch(ownerRepositoryProvider).watchTechnicianRoster();
});

final jobListProvider = FutureProvider.autoDispose.family<List<JobRecord>, JobListFilter>((
  ref,
  filter,
) {
  return ref.watch(ownerRepositoryProvider).listJobs(filter);
});

final jobByIdProvider = FutureProvider.autoDispose.family<JobRecord?, String>((
  ref,
  jobId,
) {
  return ref.watch(ownerRepositoryProvider).getJobById(jobId);
});
