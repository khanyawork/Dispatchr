import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// One selectable entry in [RoleSelectorWidget], mapping to a
/// `profiles.role` value (README Section 10).
class _RoleOption {
  const _RoleOption(this.value, this.label, this.description, this.icon);

  final String value;
  final String label;
  final String description;
  final IconData icon;
}

/// Signup role selector (`FileManifest.md`: "used at signup to assign
/// client/technician/owner"). Administrator accounts are provisioned by the
/// platform, not self-service (README Section 8.4), so `admin` is
/// intentionally excluded from this list.
///
/// A [FormField] wrapper so it composes with the rest of the signup form —
/// pass [Validators.role] as its `validator` to require a selection.
class RoleSelectorWidget extends FormField<String> {
  RoleSelectorWidget({
    super.key,
    String? initialRole,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    ValueChanged<String>? onChanged,
  }) : super(
         initialValue: initialRole,
         builder: (state) {
           return _RoleSelectorContent(
             selectedRole: state.value,
             errorText: state.errorText,
             onSelected: (role) {
               state.didChange(role);
               onChanged?.call(role);
             },
           );
         },
       );
}

class _RoleSelectorContent extends StatelessWidget {
  const _RoleSelectorContent({
    required this.selectedRole,
    required this.errorText,
    required this.onSelected,
  });

  final String? selectedRole;
  final String? errorText;
  final ValueChanged<String> onSelected;

  static const List<_RoleOption> _options = [
    _RoleOption(
      'client',
      'Client',
      'Request service and track job status',
      Icons.person_outline,
    ),
    _RoleOption(
      'technician',
      'Technician',
      'Complete assigned jobs in the field',
      Icons.build_outlined,
    ),
    _RoleOption(
      'owner',
      'Business Owner',
      'Run scheduling and dispatch for your business',
      Icons.dashboard_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final primaryColor = isDark ? DesignTokens.primaryDark : DesignTokens.primaryLight;
    final surfaceAlt = isDark ? DesignTokens.surfaceAltDark : DesignTokens.surfaceAltLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final alertColor = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final option in _options) ...[
          _RoleCard(
            option: option,
            isSelected: option.value == selectedRole,
            borderColor: borderColor,
            primaryColor: primaryColor,
            surfaceAlt: surfaceAlt,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => onSelected(option.value),
          ),
          const SizedBox(height: 12),
        ],
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: alertColor,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.borderColor,
    required this.primaryColor,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final _RoleOption option;
  final bool isSelected;
  final Color borderColor;
  final Color primaryColor;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 150-200ms ease-out color transition per README Section 5.3 —
    // no instant color snaps between selected/unselected states.
    return AnimatedContainer(
      duration: DesignTokens.hoverTransitionDuration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.08) : surfaceAlt,
        border: Border.all(
          color: isSelected ? primaryColor : borderColor,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  color: isSelected ? primaryColor : textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: DesignTokens.fontSizeMd,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: option.value,
                  groupValue: isSelected ? option.value : null,
                  activeColor: primaryColor,
                  onChanged: (_) => onTap(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
