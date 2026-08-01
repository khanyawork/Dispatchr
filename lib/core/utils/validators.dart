/// Form validation logic for Dispatchr, per `FileManifest.md`
/// (`lib/core/utils/validators.dart` — "form validation logic: email,
/// required fields"). Each method matches Flutter's
/// `String? Function(String?)` `TextFormField.validator` signature so it can
/// be wired directly into form fields across auth, client request, and
/// owner job screens (README Sections 8.1–8.3).
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
  );

  // South African-leaning but permissive: optional leading +, 7-15 digits,
  // spaces/dashes allowed between digits.
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9\s-]{6,14}$');

  /// The `profiles.role` values allowed by the database check constraint
  /// (README Section 10).
  static const List<String> validRoles = [
    'client',
    'technician',
    'owner',
    'admin',
  ];

  // ---------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------

  /// Fails if [value] is null, empty, or whitespace-only.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Runs [validators] in order, returning the first non-null error.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  // ---------------------------------------------------------------------
  // Auth (login_screen.dart, signup_screen.dart)
  // ---------------------------------------------------------------------

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Minimum 8 characters with at least one letter and one number, mirroring
  /// the seeded test-account password shape (README Section 9).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Enter a full name';
    }
    return null;
  }

  /// Signup role selection (`role_selector_widget.dart`) must match one of
  /// the `profiles.role` check-constraint values.
  static String? role(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select a role';
    }
    if (!validRoles.contains(value.trim().toLowerCase())) {
      return 'Select a valid role';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Contact details (client/technician profile fields, job assignment)
  // ---------------------------------------------------------------------

  /// Optional field — only validated if a value was entered, per README
  /// 8.1's "contact method, if the business opts in".
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Job / service request forms (new_request_screen.dart,
  // create_edit_job_screen.dart)
  // ---------------------------------------------------------------------

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Service address is required';
    }
    if (value.trim().length < 5) {
      return 'Enter a complete address';
    }
    return null;
  }

  /// `jobs.description` is nullable in the schema, so an empty description
  /// is valid — this only rejects a description that's present but too
  /// short to be useful.
  static String? jobDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 5) {
      return 'Add a bit more detail so the technician knows what to expect';
    }
    return null;
  }

  /// `jobs.scheduled_date` must not be in the past.
  static String? scheduledDate(DateTime? value) {
    if (value == null) {
      return 'Select a date';
    }
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (value.isBefore(startOfToday)) {
      return 'Date cannot be in the past';
    }
    return null;
  }
}
