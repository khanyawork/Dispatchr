import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A `jobs` row as returned by Supabase, optionally embedded with the
/// assigned technician's profile under the `technician` key.
typedef JobRecord = Map<String, dynamic>;

/// Client-scoped Supabase queries (`FileManifest.md`:
/// `lib/features/client/client_repository.dart`). Every query here is
/// additionally scoped by the `jobs` RLS policies (README Section 10),
/// which restrict a client to rows where `client_id = auth.uid()` — the
/// `client_id` filters below are defense in depth, not the sole guard.
class ClientRepository {
  ClientRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Embeds the assigned technician's name via the `assigned_technician_id`
  // foreign key (README Section 10), for request_detail_screen.dart.
  static const String _selectWithTechnician =
      '*, technician:profiles!assigned_technician_id(full_name)';

  String get _requireClientId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('ClientRepository requires an authenticated client');
    }
    return id;
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

  /// Creates a new service request (README Section 8.1). Starts in
  /// `pending` status per the `jobs.status` default (README Section 10).
  Future<JobRecord> createRequest({
    required String businessId,
    required String clientName,
    required String address,
    String? description,
    DateTime? preferredDate,
    TimeOfDay? preferredTime,
    List<String> photoUrls = const [],
  }) {
    return _client
        .from('jobs')
        .insert({
          'business_id': businessId,
          'client_id': _requireClientId,
          'client_name': clientName,
          'address': address,
          'description': description,
          'scheduled_date': preferredDate == null
              ? null
              : _dateToPostgres(preferredDate),
          'scheduled_time': preferredTime == null
              ? null
              : _timeToPostgres(preferredTime),
          'photo_urls': photoUrls,
        })
        .select(_selectWithTechnician)
        .single();
  }

  /// Live "My Requests" list (README 8.1 Home screen), newest first.
  Stream<List<JobRecord>> watchMyRequests() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('client_id', _requireClientId)
        .order('created_at', ascending: false);
  }

  /// Live single-request detail, so status changes (Pending → In Progress →
  /// Completed) reach the request detail screen in real time.
  Stream<JobRecord?> watchRequestById(String jobId) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Completed/past requests for the history screen — a plain fetch since
  /// history doesn't need live updates.
  Future<List<JobRecord>> getRequestHistory() async {
    final rows = await _client
        .from('jobs')
        .select(_selectWithTechnician)
        .eq('client_id', _requireClientId)
        .eq('status', 'completed')
        .order('scheduled_date', ascending: false);
    return List<JobRecord>.from(rows as List);
  }

  /// Cancels a request. Only valid while `status = pending` — once a
  /// technician has started work the client can no longer edit the job
  /// (README 8.1 "Cannot do"), enforced here and mirrored by RLS.
  Future<void> cancelRequest(String jobId) {
    return _client
        .from('jobs')
        .delete()
        .eq('id', jobId)
        .eq('client_id', _requireClientId)
        .eq('status', 'pending');
  }

  /// Reschedules a pending request's preferred date/time.
  Future<void> rescheduleRequest(
    String jobId, {
    required DateTime date,
    required TimeOfDay time,
  }) {
    return _client
        .from('jobs')
        .update({
          'scheduled_date': _dateToPostgres(date),
          'scheduled_time': _timeToPostgres(time),
        })
        .eq('id', jobId)
        .eq('client_id', _requireClientId)
        .eq('status', 'pending');
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});

final myRequestsProvider = StreamProvider.autoDispose<List<JobRecord>>((ref) {
  return ref.watch(clientRepositoryProvider).watchMyRequests();
});

final requestDetailProvider = StreamProvider.autoDispose
    .family<JobRecord?, String>((ref, jobId) {
      return ref.watch(clientRepositoryProvider).watchRequestById(jobId);
    });

final requestHistoryProvider = FutureProvider.autoDispose<List<JobRecord>>((
  ref,
) {
  return ref.watch(clientRepositoryProvider).getRequestHistory();
});
