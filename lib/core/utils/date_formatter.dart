import 'package:flutter/material.dart';

/// Shared date/time formatting helpers for Dispatchr, per `FileManifest.md`
/// (`lib/core/utils/date_formatter.dart`). Centralizes how `jobs.scheduled_date`
/// / `scheduled_time` (README Section 10) and timestamps are displayed across
/// client, technician, and owner screens, so formatting stays consistent
/// without depending on the `intl` package.
class DateFormatter {
  DateFormatter._();

  static const List<String> _monthAbbreviations = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdayAbbreviations = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  // ---------------------------------------------------------------------
  // Date
  // ---------------------------------------------------------------------

  /// e.g. `Jul 10, 2026` — job history, invoice lists.
  static String formatDate(DateTime date) {
    return '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// e.g. `Fri, Jul 10` — compact job cards where the year is implied.
  static String formatShortDate(DateTime date) {
    final weekday = _weekdayAbbreviations[date.weekday - 1];
    return '$weekday, ${_monthAbbreviations[date.month - 1]} ${date.day}';
  }

  // ---------------------------------------------------------------------
  // Time
  // ---------------------------------------------------------------------

  /// e.g. `2:30 PM` — formats a `TimeOfDay` (used for `jobs.scheduled_time`
  /// form fields) without requiring a `BuildContext`.
  static String formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  /// e.g. `2:30 PM` — same as [formatTimeOfDay] but for a `DateTime`.
  static String formatTime(DateTime dateTime) {
    return formatTimeOfDay(TimeOfDay.fromDateTime(dateTime));
  }

  // ---------------------------------------------------------------------
  // Combined date + time
  // ---------------------------------------------------------------------

  /// e.g. `Jul 10, 2026 at 2:30 PM` — job detail screens, notifications.
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Combines a job's separate `scheduled_date` and `scheduled_time`
  /// columns into one display string, e.g. `Fri, Jul 10 at 2:30 PM`.
  static String formatScheduledWindow(DateTime date, TimeOfDay time) {
    return '${formatShortDate(date)} at ${formatTimeOfDay(time)}';
  }

  // ---------------------------------------------------------------------
  // Relative time (notifications, "last updated" labels)
  // ---------------------------------------------------------------------

  /// e.g. `Just now`, `5m ago`, `2h ago`, `Yesterday`, `3d ago`, falling
  /// back to [formatDate] beyond a week so old entries stay legible.
  static String relativeTime(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(dateTime);

    if (difference.isNegative) {
      return formatDate(dateTime);
    }
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return formatDate(dateTime);
  }

  // ---------------------------------------------------------------------
  // Day comparisons — used for "today's jobs" views and overdue flags
  // ---------------------------------------------------------------------

  static bool isToday(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return date.year == reference.year &&
        date.month == reference.month &&
        date.day == reference.day;
  }

  /// True if [date] falls strictly before today — used to flag unassigned
  /// or incomplete jobs red per README Section 5.1.
  static bool isPastDay(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final startOfToday = DateTime(reference.year, reference.month, reference.day);
    final startOfDate = DateTime(date.year, date.month, date.day);
    return startOfDate.isBefore(startOfToday);
  }
}
