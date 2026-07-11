import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable centered empty/placeholder state — for genuine "nothing here
/// yet" states, errors, and guard messages across role home screens
/// (README Section 8's "Empty states to design for" callouts).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
