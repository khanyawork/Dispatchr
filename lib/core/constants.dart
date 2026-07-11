/// App-wide constants. README Section 10's SQL schema is the source of
/// truth for the string values below — keep these in sync with the
/// database check constraints rather than hardcoding the literals
/// elsewhere.

const String appName = 'Dispatchr';

/// `profiles.role` values (README Section 10).
abstract class AppRoles {
  static const String client = 'client';
  static const String technician = 'technician';
  static const String owner = 'owner';
  static const String admin = 'admin';

  static const List<String> values = [client, technician, owner, admin];
}

/// `jobs.status` values — the fixed pipeline from README Section 8.2:
/// Pending -> In Progress -> Completed. A technician can't skip a stage or
/// move backward without an Owner override.
abstract class JobStatuses {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';

  static const List<String> pipeline = [pending, inProgress, completed];
}

/// Supabase table names (README Section 10).
abstract class SupabaseTables {
  static const String businesses = 'businesses';
  static const String profiles = 'profiles';
  static const String jobs = 'jobs';
  static const String adminAuditLog = 'admin_audit_log';
}

/// Supabase Storage bucket names (README Section 4 "File storage" — job
/// photo uploads, proof-of-work documentation).
abstract class SupabaseBuckets {
  static const String jobPhotos = 'job-photos';
}
