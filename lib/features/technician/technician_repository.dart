import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dev/preview_mode.dart';
import '../../dev/preview_repositories.dart';

/// A `jobs` row as returned by Supabase.
typedef JobRecord = Map<String, dynamic>;

/// The fixed status pipeline (README Section 8.2): a technician can only
/// move a job forward one step at a time. Moving a job backward requires
/// an Owner override, which belongs to `owner_repository.dart`, not here.
const List<String> _statusPipeline = ['pending', 'in_progress', 'completed'];

class TechnicianRepositoryException implements Exception {
  TechnicianRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Technician-scoped Supabase queries (`FileManifest.md`:
/// `lib/features/technician/technician_repository.dart`). Every query here
/// is additionally scoped by the `jobs` RLS policy restricting a
/// technician to `assigned_technician_id = auth.uid()` (README Section 10)
/// — the filters below are defense in depth, not the sole guard.
///
/// Two columns referenced here — `profiles.is_available` and
/// `jobs.technician_notes` — extend the illustrative schema in README
/// Section 10 to support the "toggle availability" and "add completion
/// notes" capabilities from Section 8.2. Add them via a migration before
/// wiring this up against a real database.
class TechnicianRepository {
  TechnicianRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _requireTechnicianId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
        'TechnicianRepository requires an authenticated technician',
      );
    }
    return id;
  }

  static String _dateToPostgres(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Live jobs assigned to the technician, optionally scoped to a single
  /// [date] for the "My Jobs (today, default view)" screen (README 8.2).
  /// Omit [date] for the upcoming/past filter view.
  ///
  /// `.stream()` only supports a single `.eq()` filter, so the technician
  /// filter is applied server-side and the date filter (when present) is
  /// applied client-side via [Stream.map].
  Stream<List<JobRecord>> watchMyJobs({DateTime? date}) {
    final stream = _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('assigned_technician_id', _requireTechnicianId)
        .order('scheduled_time');

    if (date == null) return stream;

    final targetDate = _dateToPostgres(date);
    return stream.map(
      (rows) =>
          rows.where((row) => row['scheduled_date'] == targetDate).toList(),
    );
  }

  /// Live single-job detail for `job_detail_screen.dart`.
  Stream<JobRecord?> watchJobById(String jobId) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Advances a job exactly one step along the status pipeline. Throws if
  /// the job is already at its final status, or if [currentStatus] is
  /// stale (another update already moved it — the trailing `.eq('status',
  /// currentStatus)` makes this an optimistic-concurrency check).
  Future<void> advanceStatus(String jobId, String currentStatus) async {
    final currentIndex = _statusPipeline.indexOf(currentStatus);
    if (currentIndex == -1 || currentIndex == _statusPipeline.length - 1) {
      throw TechnicianRepositoryException(
        'Job is already at its final status',
      );
    }
    final nextStatus = _statusPipeline[currentIndex + 1];

    await _client
        .from('jobs')
        .update({'status': nextStatus})
        .eq('id', jobId)
        .eq('assigned_technician_id', _requireTechnicianId)
        .eq('status', currentStatus);
  }

  /// Appends one or more proof-of-work photo URLs (already uploaded to
  /// Supabase Storage via `storage_service.dart`) to `jobs.photo_urls`.
  Future<void> attachPhotos(String jobId, List<String> newUrls) async {
    final row = await _client
        .from('jobs')
        .select('photo_urls')
        .eq('id', jobId)
        .single();
    final existing = (row['photo_urls'] as List?)?.cast<String>() ?? const [];

    await _client
        .from('jobs')
        .update({
          'photo_urls': [...existing, ...newUrls],
        })
        .eq('id', jobId)
        .eq('assigned_technician_id', _requireTechnicianId);
  }

  /// Free-text completion notes visible to the Owner (README 8.2).
  Future<void> addCompletionNotes(String jobId, String notes) {
    return _client
        .from('jobs')
        .update({'technician_notes': notes})
        .eq('id', jobId)
        .eq('assigned_technician_id', _requireTechnicianId);
  }

  /// Current availability flag, read by `availability_toggle_widget.dart`.
  Future<bool> getAvailability() async {
    final row = await _client
        .from('profiles')
        .select('is_available')
        .eq('id', _requireTechnicianId)
        .single();
    return row['is_available'] as bool? ?? true;
  }

  /// Toggles the technician's own availability so the Owner's assignment
  /// view reflects who's free (README 8.2).
  Future<void> setAvailability(bool isAvailable) {
    return _client
        .from('profiles')
        .update({'is_available': isAvailable})
        .eq('id', _requireTechnicianId);
  }
}

final technicianRepositoryProvider = Provider<TechnicianRepository>((ref) {
  if (PreviewMode.enabled) return PreviewTechnicianRepository();
  return TechnicianRepository();
});

/// "My Jobs" default view — today only.
final myJobsTodayProvider = StreamProvider.autoDispose<List<JobRecord>>((
  ref,
) {
  return ref
      .watch(technicianRepositoryProvider)
      .watchMyJobs(date: DateTime.now());
});

/// "My Jobs" with the upcoming/past date filter (README 8.2); pass `null`
/// for all assigned jobs regardless of date.
final myJobsProvider = StreamProvider.autoDispose.family<List<JobRecord>, DateTime?>((
  ref,
  date,
) {
  return ref.watch(technicianRepositoryProvider).watchMyJobs(date: date);
});

final jobDetailProvider = StreamProvider.autoDispose.family<JobRecord?, String>((
  ref,
  jobId,
) {
  return ref.watch(technicianRepositoryProvider).watchJobById(jobId);
});

final technicianAvailabilityProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  return ref.watch(technicianRepositoryProvider).getAvailability();
});
