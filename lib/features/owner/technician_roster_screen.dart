import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'owner_repository.dart';

/// README Section 8.3's Technician roster: list of technicians, their
/// availability, current job, and a performance summary. Owners can also
/// deactivate a technician and — since Phase 1 has no email-invite flow —
/// link an already-registered, unassigned technician into their roster
/// (a Phase-1 stand-in for README's "invite" capability).
class TechnicianRosterScreen extends ConsumerStatefulWidget {
  const TechnicianRosterScreen({super.key});

  @override
  ConsumerState<TechnicianRosterScreen> createState() =>
      _TechnicianRosterScreenState();
}

class _TechnicianRosterScreenState
    extends ConsumerState<TechnicianRosterScreen> {
  bool _isLoadingBusiness = true;
  String? _businessId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    try {
      final businessId = await ref
          .read(ownerRepositoryProvider)
          .fetchOwnBusinessId();

      if (!mounted) return;
      setState(() {
        _businessId = businessId;
        _isLoadingBusiness = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = "Couldn't load your business.";
        _isLoadingBusiness = false;
      });
    }
  }

  void _showAddTechnicianSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _AddTechnicianSheet(businessId: _businessId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Roster'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: AppSession.instance.signOut,
          ),
        ],
      ),
      body: _isLoadingBusiness
          ? const SkeletonLoader()
          : _loadError != null
          ? EmptyState(message: _loadError!, icon: Icons.error_outline)
          : _businessId == null
          ? const EmptyState(
              message: 'No business is set up yet.',
              icon: Icons.business_outlined,
            )
          : _RosterList(businessId: _businessId!),
      floatingActionButton: _businessId == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add technician',
              onPressed: _showAddTechnicianSheet,
              child: const Icon(Icons.person_add_alt_1_outlined),
            ),
    );
  }
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerRepository = ref.watch(ownerRepositoryProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ownerRepository.watchBusinessProfiles(businessId),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return const EmptyState(
            message: "Couldn't load the roster. Pull to retry.",
            icon: Icons.error_outline,
          );
        }

        if (!profileSnapshot.hasData) {
          return const SkeletonLoader();
        }

        final technicians = profileSnapshot.data!
            .where((row) => row['role'] == AppRoles.technician)
            .map(_TechnicianProfile.fromRow)
            .toList(growable: false);

        if (technicians.isEmpty) {
          return const EmptyState(
            message: 'No technicians on your roster yet.\nTap + to add one.',
            icon: Icons.groups_outlined,
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: ownerRepository.watchBusinessJobs(businessId),
          builder: (context, jobSnapshot) {
            final jobRows = jobSnapshot.data ?? const [];

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: technicians.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tech = technicians[index];
                final techJobs = jobRows.where(
                  (row) => row['assigned_technician_id'] == tech.id,
                );
                final currentJob = techJobs
                    .cast<Map<String, dynamic>?>()
                    .firstWhere(
                      (row) => row!['status'] == JobStatuses.inProgress,
                      orElse: () => null,
                    );
                final completedCount = techJobs
                    .where((row) => row['status'] == JobStatuses.completed)
                    .length;

                return _TechnicianCard(
                  technician: tech,
                  currentJobAddress: currentJob?['address'] as String?,
                  completedCount: completedCount,
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Lightweight stand-in for the row shape until a shared profile model
/// exists.
class _TechnicianProfile {
  const _TechnicianProfile({
    required this.id,
    required this.fullName,
    required this.isAvailable,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final bool isAvailable;
  final bool isActive;

  factory _TechnicianProfile.fromRow(Map<String, dynamic> row) {
    final name = row['full_name'] as String?;
    return _TechnicianProfile(
      id: row['id'] as String,
      fullName: (name != null && name.trim().isNotEmpty)
          ? name
          : 'Unnamed technician',
      isAvailable: row['is_available'] as bool? ?? true,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

class _TechnicianCard extends ConsumerWidget {
  const _TechnicianCard({
    required this.technician,
    required this.currentJobAddress,
    required this.completedCount,
  });

  final _TechnicianProfile technician;
  final String? currentJobAddress;
  final int completedCount;

  Future<void> _setActive(WidgetRef ref, bool isActive) {
    return ref
        .read(ownerRepositoryProvider)
        .setTechnicianActive(technician.id, isActive);
  }

  Future<void> _handleMenuSelection(
    BuildContext context,
    WidgetRef ref,
    bool setActive,
  ) async {
    if (!setActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Deactivate technician?'),
          content: Text(
            '${technician.fullName} will no longer be able to access '
            'assigned jobs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _setActive(ref, setActive);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: technician.isActive ? 1 : 0.5,
      child: Material(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.fullName,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        _AvailabilityTag(
                          isAvailable: technician.isAvailable,
                          isActive: technician.isActive,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<bool>(
                    tooltip: 'More actions',
                    onSelected: (setActive) =>
                        _handleMenuSelection(context, ref, setActive),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: !technician.isActive,
                        child: Text(
                          technician.isActive ? 'Deactivate' : 'Reactivate',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentJobAddress ?? 'No active job right now',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$completedCount job${completedCount == 1 ? '' : 's'} '
                    'completed',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.isAvailable, required this.isActive});

  final bool isAvailable;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    if (!isActive) {
      return Text(
        'Deactivated',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final color = isAvailable ? colors.success : colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable ? 'Available' : 'Unavailable',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Bottom sheet for README Section 8.3's "invite" capability, Phase-1
/// style: pick an already-registered technician who isn't linked to a
/// business yet and add them to this roster.
class _AddTechnicianSheet extends ConsumerStatefulWidget {
  const _AddTechnicianSheet({required this.businessId});

  final String businessId;

  @override
  ConsumerState<_AddTechnicianSheet> createState() =>
      _AddTechnicianSheetState();
}

class _AddTechnicianSheetState extends ConsumerState<_AddTechnicianSheet> {
  late final Future<List<Map<String, dynamic>>> _unassignedFuture =
      _fetchUnassigned();
  String? _errorMessage;
  String? _addingId;

  Future<List<Map<String, dynamic>>> _fetchUnassigned() {
    return ref.read(ownerRepositoryProvider).fetchUnassignedTechnicians();
  }

  Future<void> _addTechnician(String id) async {
    setState(() {
      _addingId = id;
      _errorMessage = null;
    });

    try {
      await ref
          .read(ownerRepositoryProvider)
          .assignTechnicianToBusiness(id, widget.businessId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _errorMessage = "Couldn't add that technician.");
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add an existing technician',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Registered technicians not yet on any roster.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _unassignedFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final technicians = snapshot.data!;
                if (technicians.isEmpty) {
                  return const EmptyState(
                    message: 'No unassigned technicians right now.',
                    icon: Icons.person_search_outlined,
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      final tech = technicians[index];
                      final id = tech['id'] as String;
                      final name =
                          tech['full_name'] as String? ??
                          'Unnamed technician';

                      return ListTile(
                        title: Text(name),
                        trailing: _addingId == id
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton(
                                onPressed: () => _addTechnician(id),
                                child: const Text('Add'),
                              ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
