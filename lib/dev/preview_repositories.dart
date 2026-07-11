// Fake repositories that back preview mode (see `preview_mode.dart`). Each
// one implements the same public interface as its real Supabase
// counterpart and reads/writes the single shared `PreviewStore`, so a
// change made in one role's screens (e.g. a technician advancing a job's
// status) is immediately visible in another role's screens, the same way a
// Supabase Realtime update would be.

import 'dart:io';

import 'package:flutter/material.dart';

import '../features/client/client_repository.dart';
import '../features/jobs/job_repository.dart';
import '../features/owner/owner_repository.dart';
import '../features/technician/technician_repository.dart' hide JobRecord;
import 'preview_data.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}:00';

class PreviewJobRepository implements JobRepository {
  @override
  Stream<List<Map<String, dynamic>>> watchClientJobs(String clientId) {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows.where((r) => r['client_id'] == clientId).toList(),
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTechnicianJobs(
    String technicianId,
  ) {
    return PreviewStore.instance.watchJobs().map(
      (rows) =>
          rows.where((r) => r['assigned_technician_id'] == technicianId).toList(),
    );
  }

  @override
  Stream<Map<String, dynamic>?> watchJob(String jobId) {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows
          .cast<Map<String, dynamic>?>()
          .firstWhere((r) => r!['id'] == jobId, orElse: () => null),
    );
  }

  @override
  Future<String> createJob(Map<String, dynamic> data) async {
    return PreviewStore.instance.createJob(data);
  }

  @override
  Future<void> updateStatus(String jobId, String status) async {
    PreviewStore.instance.updateJob(jobId, {'status': status});
  }

  @override
  Future<void> updateCompletionNotes(String jobId, String notes) async {
    PreviewStore.instance.updateJob(jobId, {'technician_notes': notes});
  }

  @override
  Future<void> setPhotoUrls(String jobId, List<String> photoUrls) async {
    PreviewStore.instance.updateJob(jobId, {'photo_urls': photoUrls});
  }

  @override
  Future<String> uploadJobPhoto({
    required String jobId,
    required File file,
    required String fileName,
  }) async {
    return Uri.file(file.path).toString();
  }
}

class PreviewClientRepository implements ClientRepository {
  @override
  Future<JobRecord> createRequest({
    required String businessId,
    required String clientName,
    required String address,
    String? description,
    DateTime? preferredDate,
    TimeOfDay? preferredTime,
    List<String> photoUrls = const [],
  }) async {
    final id = PreviewStore.instance.createJob({
      'business_id': businessId,
      'client_id': PreviewIds.client,
      'client_name': clientName,
      'address': address,
      'description': description,
      'scheduled_date': preferredDate == null
          ? null
          : _formatDate(preferredDate),
      'scheduled_time': preferredTime == null
          ? null
          : _formatTime(preferredTime),
      'status': 'pending',
      'photo_urls': photoUrls,
    });
    return PreviewStore.instance.jobs.firstWhere((j) => j['id'] == id);
  }

  @override
  Stream<List<JobRecord>> watchMyRequests() {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows.where((r) => r['client_id'] == PreviewIds.client).toList(),
    );
  }

  @override
  Stream<JobRecord?> watchRequestById(String jobId) {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows
          .cast<JobRecord?>()
          .firstWhere((r) => r!['id'] == jobId, orElse: () => null),
    );
  }

  @override
  Future<List<JobRecord>> getRequestHistory() async {
    return PreviewStore.instance.jobs
        .where(
          (r) => r['client_id'] == PreviewIds.client && r['status'] == 'completed',
        )
        .toList();
  }

  @override
  Future<void> cancelRequest(String jobId) async {
    PreviewStore.instance.deleteJob(jobId);
  }

  @override
  Future<void> rescheduleRequest(
    String jobId, {
    required DateTime date,
    required TimeOfDay time,
  }) async {
    PreviewStore.instance.updateJob(jobId, {
      'scheduled_date': _formatDate(date),
      'scheduled_time': _formatTime(time),
    });
  }
}

const List<String> _statusPipeline = ['pending', 'in_progress', 'completed'];

class PreviewTechnicianRepository implements TechnicianRepository {
  @override
  Stream<List<JobRecord>> watchMyJobs({DateTime? date}) {
    final stream = PreviewStore.instance.watchJobs().map(
      (rows) => rows
          .where((r) => r['assigned_technician_id'] == PreviewIds.technician)
          .toList(),
    );
    if (date == null) return stream;
    final targetDate = _formatDate(date);
    return stream.map(
      (rows) => rows.where((r) => r['scheduled_date'] == targetDate).toList(),
    );
  }

  @override
  Stream<JobRecord?> watchJobById(String jobId) {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows
          .cast<JobRecord?>()
          .firstWhere((r) => r!['id'] == jobId, orElse: () => null),
    );
  }

  @override
  Future<void> advanceStatus(String jobId, String currentStatus) async {
    final currentIndex = _statusPipeline.indexOf(currentStatus);
    if (currentIndex == -1 || currentIndex == _statusPipeline.length - 1) {
      throw TechnicianRepositoryException('Job is already at its final status');
    }
    PreviewStore.instance.updateJob(jobId, {
      'status': _statusPipeline[currentIndex + 1],
    });
  }

  @override
  Future<void> attachPhotos(String jobId, List<String> newUrls) async {
    final job = PreviewStore.instance.jobs.firstWhere(
      (j) => j['id'] == jobId,
      orElse: () => const {},
    );
    final existing = (job['photo_urls'] as List?)?.cast<String>() ?? const [];
    PreviewStore.instance.updateJob(jobId, {
      'photo_urls': [...existing, ...newUrls],
    });
  }

  @override
  Future<void> addCompletionNotes(String jobId, String notes) async {
    PreviewStore.instance.updateJob(jobId, {'technician_notes': notes});
  }

  @override
  Future<bool> getAvailability() async {
    final profile = PreviewStore.instance.profiles.firstWhere(
      (p) => p['id'] == PreviewIds.technician,
      orElse: () => const {},
    );
    return profile['is_available'] as bool? ?? true;
  }

  @override
  Future<void> setAvailability(bool isAvailable) async {
    PreviewStore.instance.updateProfile(PreviewIds.technician, {
      'is_available': isAvailable,
    });
  }
}

class PreviewOwnerRepository implements OwnerRepository {
  @override
  Future<String?> fetchOwnBusinessId() async => PreviewIds.businessId;

  @override
  Stream<List<Map<String, dynamic>>> watchBusinessJobs(String businessId) {
    return PreviewStore.instance.watchJobs().map(
      (rows) => rows.where((r) => r['business_id'] == businessId).toList(),
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBusinessProfiles(
    String businessId,
  ) {
    return PreviewStore.instance.watchProfiles().map(
      (rows) => rows.where((r) => r['business_id'] == businessId).toList(),
    );
  }

  @override
  Future<void> setTechnicianActive(String technicianId, bool isActive) async {
    PreviewStore.instance.updateProfile(technicianId, {
      'is_active': isActive,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUnassignedTechnicians() async {
    return PreviewStore.instance.profiles
        .where((p) => p['role'] == 'technician' && p['business_id'] == null)
        .map((p) => {'id': p['id'], 'full_name': p['full_name']})
        .toList();
  }

  @override
  Future<void> assignTechnicianToBusiness(
    String technicianId,
    String businessId,
  ) async {
    PreviewStore.instance.updateProfile(technicianId, {
      'business_id': businessId,
    });
  }
}
