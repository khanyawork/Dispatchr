import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import 'admin_repository.dart';

/// Read-oriented support view into a specific tenant (README 8.4). Every
/// open requires a logged reason — "every access is logged with timestamp
/// and reason, never silent" — enforced here via a blocking dialog before
/// any tenant data is fetched. `FileManifest.md`:
/// `lib/features/admin/business_detail_screen.dart`.
class BusinessDetailScreen extends ConsumerStatefulWidget {
  const BusinessDetailScreen({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<BusinessDetailScreen> createState() =>
      _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  BusinessDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _promptForReasonAndLoad(),
    );
  }

  Future<void> _promptForReasonAndLoad() async {
    final reason = await _askReason();
    if (reason == null) {
      // No reason given — can't view tenant data without one, so back out
      // rather than silently loading anyway.
      if (mounted) context.pop();
      return;
    }

    try {
      final detail = await ref
          .read(adminRepositoryProvider)
          .getBusinessDetail(widget.businessId, reason: reason);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load business details';
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reason for access'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Why are you viewing this tenant's data?",
              helperText: 'Recorded in the audit trail (README 8.4).',
            ),
            validator: (v) => Validators.required(v, fieldName: 'A reason'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus() async {
    final detail = _detail;
    if (detail == null) return;
    final isActive = (detail.business['status'] as String? ?? 'active') == 'active';

    try {
      if (isActive) {
        await ref.read(adminRepositoryProvider).suspendBusiness(widget.businessId);
      } else {
        await ref.read(adminRepositoryProvider).reactivateBusiness(widget.businessId);
      }
      if (!mounted) return;
      setState(() {
        _detail = BusinessDetail(
          business: {
            ...detail.business,
            'status': isActive ? 'suspended' : 'active',
          },
          ownerName: detail.ownerName,
          technicianCount: detail.technicianCount,
          jobCount: detail.jobCount,
          recentJobs: detail.recentJobs,
        );
      });
      context.showSuccessSnackBar(
        isActive ? 'Business suspended' : 'Business reactivated',
      );
    } catch (_) {
      if (mounted) context.showErrorSnackBar('Could not update business status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = context.isDarkMode
        ? DesignTokens.alertDark
        : DesignTokens.alertLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(_errorMessage!, style: TextStyle(color: alert)),
            )
          : _detail == null
          ? const SizedBox.shrink()
          : _DetailBody(detail: _detail!, onToggleStatus: _toggleStatus),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.onToggleStatus});

  final BusinessDetail detail;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final success = isDark
        ? DesignTokens.successDark
        : DesignTokens.successLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;

    final business = detail.business;
    final isActive = (business['status'] as String? ?? 'active') == 'active';
    final createdAt = business['created_at'] != null
        ? DateTime.tryParse(business['created_at'] as String)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          business['name'] as String? ?? 'Unnamed business',
          style: TextStyle(
            color: textPrimary,
            fontSize: DesignTokens.fontSizeXl,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Owner: ${detail.ownerName ?? 'Unknown'}',
          style: TextStyle(color: textSecondary),
        ),
        if (createdAt != null)
          Text(
            'Joined ${DateFormatter.formatDate(createdAt)}',
            style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? success : alert).withValues(alpha: 0.12),
                border: Border.all(color: isActive ? success : alert),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Suspended',
                style: TextStyle(
                  color: isActive ? success : alert,
                  fontWeight: FontWeight.w600,
                  fontSize: DesignTokens.fontSizeXs,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onToggleStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: isActive ? alert : success,
              ),
              child: Text(isActive ? 'Suspend Business' : 'Reactivate Business'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Technicians',
                value: detail.technicianCount.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Jobs',
                value: detail.jobCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'RECENT JOBS',
          style: TextStyle(
            color: textSecondary,
            fontSize: DesignTokens.fontSizeXs,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (detail.recentJobs.isEmpty)
          Text('No jobs recorded yet', style: TextStyle(color: textSecondary))
        else
          for (final job in detail.recentJobs) _JobRow(job: job),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceAlt,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: DesignTokens.fontSizeXxl,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm)),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final JobRecord job;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;

    final createdAt = job['created_at'] != null
        ? DateTime.tryParse(job['created_at'] as String)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              job['client_name'] as String? ?? job['address'] as String? ?? 'Job',
              style: TextStyle(color: textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (createdAt != null)
            Text(
              DateFormatter.formatShortDate(createdAt),
              style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeXs),
            ),
        ],
      ),
    );
  }
}
