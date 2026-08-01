import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import 'technician_repository.dart';

/// Technician availability toggle (README 8.2: "Toggle their own
/// availability (available/unavailable) so the Owner's assignment view
/// reflects who's free"). `FileManifest.md`:
/// `lib/features/technician/availability_toggle_widget.dart`.
///
/// Applies the toggle optimistically and rolls back with an error snackbar
/// if the write fails, since this sits at the top of `my_jobs_screen.dart`
/// and shouldn't block the rest of the screen while saving.
class AvailabilityToggleWidget extends ConsumerStatefulWidget {
  const AvailabilityToggleWidget({super.key});

  @override
  ConsumerState<AvailabilityToggleWidget> createState() =>
      _AvailabilityToggleWidgetState();
}

class _AvailabilityToggleWidgetState
    extends ConsumerState<AvailabilityToggleWidget> {
  bool? _optimisticValue;
  bool _isSaving = false;

  Future<void> _toggle(bool newValue) async {
    final previous = _optimisticValue;
    setState(() {
      _optimisticValue = newValue;
      _isSaving = true;
    });

    try {
      await ref.read(technicianRepositoryProvider).setAvailability(newValue);
      ref.invalidate(technicianAvailabilityProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticValue = previous);
      context.showErrorSnackBar('Could not update availability');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(technicianAvailabilityProvider);
    final isDark = context.isDarkMode;
    final success = isDark
        ? DesignTokens.successDark
        : DesignTokens.successLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;

    return availabilityAsync.when(
      loading: () => const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Text(
        'Could not load availability',
        style: TextStyle(color: alert, fontSize: DesignTokens.fontSizeSm),
      ),
      data: (serverValue) {
        final isAvailable = _optimisticValue ?? serverValue;

        // 150-200ms ease-out color transition on state change, per README
        // Section 5.3 — no instant color snaps.
        return AnimatedContainer(
          duration: DesignTokens.hoverTransitionDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceAlt,
            border: Border.all(color: isAvailable ? success : border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icon paired with the toggle so state isn't conveyed by
              // color alone (README Section 5.5 accessibility).
              Icon(
                isAvailable ? Icons.check_circle : Icons.pause_circle_outline,
                color: isAvailable ? success : textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAvailable ? 'Available for jobs' : 'Unavailable',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? success : textSecondary,
                  ),
                ),
              ),
              Switch(
                value: isAvailable,
                activeThumbColor: success,
                onChanged: _isSaving ? null : _toggle,
              ),
            ],
          ),
        );
      },
    );
  }
}
