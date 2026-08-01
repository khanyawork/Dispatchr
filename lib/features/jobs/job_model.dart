import 'package:flutter/material.dart';

import 'job_status.dart';

/// A `jobs` row (README Section 10), typed for the shared `features/jobs`
/// layer. `FileManifest.md`: `lib/features/jobs/job_model.dart`.
///
/// The client/technician/owner/admin repositories built so far read and
/// write this table as raw `Map<String, dynamic>` rows directly — this
/// class doesn't retrofit those, it's the typed shape `job_repository.dart`
/// and `job_provider.dart` (the remaining files in this folder per the
/// manifest) can be built against, and existing repositories can migrate
/// onto later.
///
/// `technicianNotes` extends the illustrative schema in README Section 10
/// — see the note in `technician_repository.dart` — and is only populated
/// when the column is present in the source row.
@immutable
class Job {
  const Job({
    required this.id,
    required this.businessId,
    required this.clientName,
    required this.address,
    required this.status,
    required this.createdAt,
    this.clientId,
    this.assignedTechnicianId,
    this.description,
    this.scheduledDate,
    this.scheduledTime,
    this.photoUrls = const [],
    this.technicianNotes,
    this.technicianName,
  });

  final String id;
  final String businessId;
  final String? clientId;
  final String? assignedTechnicianId;
  final String clientName;
  final String address;
  final String? description;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final JobStatus status;
  final List<String> photoUrls;
  final String? technicianNotes;
  final DateTime createdAt;

  /// Resolved from an embedded `technician:profiles!assigned_technician_id
  /// (full_name)` select (e.g. `client_repository.dart`'s
  /// `_selectWithTechnician`) — `null` unless the query that produced this
  /// row asked for that embed.
  final String? technicianName;

  bool get isUnassigned => assignedTechnicianId == null;

  factory Job.fromMap(Map<String, dynamic> row) {
    return Job(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      clientId: row['client_id'] as String?,
      assignedTechnicianId: row['assigned_technician_id'] as String?,
      clientName: row['client_name'] as String? ?? '',
      address: row['address'] as String? ?? '',
      description: row['description'] as String?,
      scheduledDate: _parseDate(row['scheduled_date'] as String?),
      scheduledTime: _parseTime(row['scheduled_time'] as String?),
      status: JobStatus.fromValueOrDefault(row['status'] as String?),
      photoUrls: (row['photo_urls'] as List?)?.cast<String>() ?? const [],
      technicianNotes: row['technician_notes'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      technicianName: (row['technician'] as Map?)?['full_name'] as String?,
    );
  }

  /// The full persisted shape, in the format Supabase expects for
  /// insert/update — dates/times are re-encoded to Postgres `date`/`time`
  /// text, matching the `_dateToPostgres`/`_timeToPostgres` helpers
  /// duplicated across the role repositories today.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'client_id': clientId,
      'assigned_technician_id': assignedTechnicianId,
      'client_name': clientName,
      'address': address,
      'description': description,
      'scheduled_date': scheduledDate == null ? null : _formatDate(scheduledDate!),
      'scheduled_time': scheduledTime == null ? null : _formatTime(scheduledTime!),
      'status': status.value,
      'photo_urls': photoUrls,
      'technician_notes': technicianNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Job copyWith({
    String? clientId,
    String? assignedTechnicianId,
    String? clientName,
    String? address,
    String? description,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    JobStatus? status,
    List<String>? photoUrls,
    String? technicianNotes,
    String? technicianName,
  }) {
    return Job(
      id: id,
      businessId: businessId,
      createdAt: createdAt,
      clientId: clientId ?? this.clientId,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      photoUrls: photoUrls ?? this.photoUrls,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      technicianName: technicianName ?? this.technicianName,
    );
  }

  static DateTime? _parseDate(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  @override
  bool operator ==(Object other) => other is Job && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Job(id: $id, status: ${status.value}, client: $clientName)';
}
