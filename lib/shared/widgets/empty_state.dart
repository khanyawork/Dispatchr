import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable centered empty/placeholder state — for genuine "nothing here
/// yet" states, errors, and guard messages across role home screens
/// (README Section 8's "Empty states to design for" callouts).
///
/// Rather than a bare grey glyph, the icon sits inside a soft concentric
/// tinted disc (surfaceAlt fill with a hairline ring and a faint teal
/// inner halo) so the empty state reads as an intentional design moment
/// instead of a default placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Concentric soft backdrop: outer surfaceAlt disc with a
              // hairline ring, inner teal-tinted halo behind the glyph.
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
