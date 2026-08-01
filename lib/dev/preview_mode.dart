/// Runtime flag flipped by the login screen's debug-only bypass buttons
/// (see `login_screen.dart`) so the app can be browsed end to end without a
/// working Supabase/database connection. Every repository provider checks
/// this before touching Supabase; `preview_data.dart` holds the fake data
/// and ids those repositories serve when it's on, and
/// `preview_repositories.dart` holds the fake repositories themselves.
class PreviewMode {
  PreviewMode._();

  static bool enabled = false;
}
