/// The fixed `jobs.status` pipeline (README Section 10's check constraint:
/// `status in ('pending','in_progress','completed')`). `FileManifest.md`:
/// `lib/features/jobs/job_status.dart`.
enum JobStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  const JobStatus(this.value, this.label);

  /// The exact string stored in `jobs.status`.
  final String value;

  /// Human-readable label for status badges/chips across role screens.
  final String label;

  /// Throws if [value] isn't one of the three known statuses.
  static JobStatus fromValue(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown job status: $value'),
    );
  }

  /// Parses a possibly-null/unrecognized value, falling back to [pending]
  /// — the same default as the `jobs.status` column (README Section 10).
  static JobStatus fromValueOrDefault(String? value) {
    if (value == null) return JobStatus.pending;
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => JobStatus.pending,
    );
  }

  /// The next stage in the pipeline, in declaration order (which matches
  /// the pipeline order), or `null` if already at the final stage.
  JobStatus? get next {
    final nextIndex = index + 1;
    return nextIndex < JobStatus.values.length
        ? JobStatus.values[nextIndex]
        : null;
  }

  bool get isPending => this == JobStatus.pending;

  bool get isInProgress => this == JobStatus.inProgress;

  bool get isCompleted => this == JobStatus.completed;

  /// Whether moving from this status to [target] is a single forward step
  /// along the pipeline (README 8.2: a technician "cannot skip stages,
  /// cannot move a job backward"). An Owner's manual override
  /// (README 8.3) is exempt from this check by design — it calls
  /// `updateJob(status: ...)` directly rather than going through this.
  bool canAdvanceTo(JobStatus target) => next == target;
}
