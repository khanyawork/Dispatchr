import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_providers.dart';
import '../../core/constants.dart';

/// Shared job CRUD logic used across the Client, Technician, and Owner
/// flows (README's `jobs` table, Section 10) — the cross-role complement
/// to `owner_repository.dart` (business-scoped queries) and the
/// not-yet-built `client_repository.dart`/`technician_repository.dart`.
class JobRepository {
  const JobRepository(this._client);

  final SupabaseClient _client;

  /// A client's own requests, newest first (README Section 8.1).
  Stream<List<Map<String, dynamic>>> watchClientJobs(String clientId) {
    return _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
  }

  /// Jobs assigned to a technician, ordered by scheduled time — never
  /// another technician's jobs (README Section 8.2).
  Stream<List<Map<String, dynamic>>> watchTechnicianJobs(
    String technicianId,
  ) {
    return _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq('assigned_technician_id', technicianId)
        .order('scheduled_time');
  }

  /// A single job by id, or null if it doesn't exist / isn't visible to
  /// the caller under RLS.
  Stream<Map<String, dynamic>?> watchJob(String jobId) {
    return _client
        .from(SupabaseTables.jobs)
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Creates a job — a client's own request (README Section 8.1) or an
  /// Owner-created job (README Section 8.3). Returns the new job's id.
  Future<String> createJob(Map<String, dynamic> data) async {
    final row = await _client
        .from(SupabaseTables.jobs)
        .insert(data)
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Advances (or overrides) a job's status along the Pending -> In
  /// Progress -> Completed pipeline (README Section 8.2).
  Future<void> updateStatus(String jobId, String status) {
    return _client
        .from(SupabaseTables.jobs)
        .update({'status': status})
        .eq('id', jobId);
  }

  /// Sets the technician's free-text completion notes
  /// (README Section 8.2).
  Future<void> updateCompletionNotes(String jobId, String notes) {
    return _client
        .from(SupabaseTables.jobs)
        .update({'completion_notes': notes})
        .eq('id', jobId);
  }

  /// Replaces a job's `photo_urls`. Callers pass the full desired list
  /// (e.g. `[...existing, newUrl]`) since Postgrest has no atomic
  /// array-append for this column type.
  Future<void> setPhotoUrls(String jobId, List<String> photoUrls) {
    return _client
        .from(SupabaseTables.jobs)
        .update({'photo_urls': photoUrls})
        .eq('id', jobId);
  }

  /// Uploads a photo to the `job-photos` bucket under [jobId] and returns
  /// its public URL. Used for both a client's issue photos
  /// (README Section 8.1) and a technician's proof-of-work photos
  /// (README Section 8.2). Should move to `storage_service.dart` once
  /// that file exists, per FileManifest.md.
  Future<String> uploadJobPhoto({
    required String jobId,
    required File file,
    required String fileName,
  }) async {
    final path = '$jobId/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage.from(SupabaseBuckets.jobPhotos).upload(path, file);
    return _client.storage.from(SupabaseBuckets.jobPhotos).getPublicUrl(path);
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(ref.watch(supabaseClientProvider));
});
