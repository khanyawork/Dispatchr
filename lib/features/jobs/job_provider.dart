import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'job_repository.dart';

/// Riverpod wrappers around `job_repository.dart`'s Supabase Realtime
/// streams — the "shared job state/streams" FileManifest.md calls for.
/// Screens `ref.watch()` these and get an `AsyncValue` with built-in
/// loading/error/data states instead of hand-rolling a `StreamBuilder`.
///
/// `autoDispose` matters here: these are keyed by a runtime id
/// (clientId/technicianId/jobId), so without it every distinct id a user
/// has ever navigated to would keep its Realtime subscription open for
/// the rest of the session instead of closing when no longer watched.

/// A client's own requests, newest first (README Section 8.1).
final clientJobsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, clientId) {
      return ref.watch(jobRepositoryProvider).watchClientJobs(clientId);
    });

/// Jobs assigned to a technician (README Section 8.2).
final technicianJobsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, technicianId) {
      return ref
          .watch(jobRepositoryProvider)
          .watchTechnicianJobs(technicianId);
    });

/// A single job by id, or null if it doesn't exist / isn't visible under
/// RLS (`job_detail_screen.dart`).
final jobProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, jobId) {
      return ref.watch(jobRepositoryProvider).watchJob(jobId);
    });
