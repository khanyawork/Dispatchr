import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/app_providers.dart';
import '../../app/router.dart';
import '../../core/constants.dart';

/// README Section 8's self-service sign-up, offering the three roles a
/// person can pick for themselves — Client, Technician, Owner. Admin
/// accounts are provisioned separately (Section 8.4) and never appear here.
///
/// An Owner signing up creates a new `businesses` row (they need one to run
/// jobs against). A Technician or Client signing up gets `business_id: null`
/// for now — Section 8.3 has the Owner "invite"/manage technicians and
/// clients after the fact, and no business-picker/invite-code flow exists
/// yet to join one at signup.
///
/// Talks to Supabase directly for now, same as `login_screen.dart` — move
/// this into `auth_repository.dart`/`auth_provider.dart` once they exist.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();

  UserRole _selectedRole = UserRole.client;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final client = ref.read(supabaseClientProvider);

    try {
      final authResponse = await client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = authResponse.user;
      if (user == null) {
        throw const AuthException('Sign-up did not return a user.');
      }

      String? businessId;
      if (_selectedRole == UserRole.owner) {
        final business = await client
            .from(SupabaseTables.businesses)
            .insert({
              'name': _businessNameController.text.trim(),
              'owner_id': user.id,
            })
            .select('id')
            .single();
        businessId = business['id'] as String;
      }

      await client.from(SupabaseTables.profiles).insert({
        'id': user.id,
        'business_id': businessId,
        'full_name': _fullNameController.text.trim(),
        'role': _selectedRole.value,
      });

      if (authResponse.session != null) {
        AppSession.instance.signIn(_selectedRole);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account.'),
          ),
        );
        context.go(AppRoutes.login);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateBusinessName(String? value) {
    if (_selectedRole != UserRole.owner) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _RoleSelector(
                      selectedRole: _selectedRole,
                      onChanged: (role) =>
                          setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Full name is required'
                          : null,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: _selectedRole == UserRole.owner
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextFormField(
                                controller: _businessNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Business name',
                                ),
                                validator: _validateBusinessName,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SignupButton(
                      isSubmitting: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }
}

/// Lets the person signing up choose which of the three self-service roles
/// they are (README Section 8; Admin is provisioned separately, Section
/// 8.4). Will move to `lib/features/auth/role_selector_widget.dart` once
/// that file exists, per FileManifest.md.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  static const _selectableRoles = [
    UserRole.client,
    UserRole.technician,
    UserRole.owner,
  ];

  static const _labels = {
    UserRole.client: 'Client',
    UserRole.technician: 'Technician',
    UserRole.owner: 'Owner',
  };

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: _selectableRoles
          .map(
            (role) => ButtonSegment(value: role, label: Text(_labels[role]!)),
          )
          .toList(),
      selected: {selectedRole},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// Primary action button using the hover/press transition from README
/// Section 5.3 (150–200ms ease-out to the `-hover` token) — mirrors
/// `login_screen.dart`'s `_LoginButton`. Will be replaced by
/// `shared/widgets/primary_button.dart` once that's built.
class _SignupButton extends StatelessWidget {
  const _SignupButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 180),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return colors.primaryHover;
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onPrimary,
              ),
            )
          : const Text('Sign Up'),
    );
  }
}
