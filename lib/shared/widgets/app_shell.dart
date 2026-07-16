import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import 'app_logo.dart';

/// One entry in the [AppShell] navigation rail.
class AppShellDestination {
  const AppShellDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  /// Icon shown when the destination is not selected.
  final IconData icon;

  /// Icon shown when the destination is selected (falls back to [icon]).
  final IconData? selectedIcon;

  final String label;

  /// Invoked when the destination is chosen. Navigation stays in the
  /// caller's hands — the shell is layout-only and owns no routes.
  final VoidCallback onTap;
}

/// Responsive command-center shell for the desktop-heavy Owner/Admin
/// surfaces (README describes Owner/Admin as used from a desktop window as
/// often as a phone).
///
/// Layout per the breakpoints in `context_extensions.dart` (not
/// re-declared here):
///
///  * **Desktop** (`context.isDesktop`) — persistent extended
///    [NavigationRail] on the left with the Dispatchr wordmark at the top,
///    a hairline separator, and a flat 64px content header carrying
///    [title]/[actions].
///  * **Tablet** (`context.isTablet`) — the same rail collapsed to
///    icons-with-labels, mark-only branding.
///  * **Mobile** — the rail disappears entirely; [body] renders under a
///    normal [AppBar] so phone screens keep their existing AppBar-based
///    navigation. [destinations] are simply not shown.
///
/// The shell is self-contained and owns no navigation state beyond
/// highlighting [currentIndex]; taps are delegated to each destination's
/// `onTap`.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  /// Index into [destinations] to highlight as selected.
  final int currentIndex;

  final List<AppShellDestination> destinations;

  /// The screen content, rendered to the right of the rail (or full-bleed
  /// on mobile).
  final Widget body;

  /// Optional screen title — AppBar title on mobile, content-header
  /// heading on rail layouts.
  final String? title;

  /// Optional trailing actions (icon buttons etc.) — AppBar actions on
  /// mobile, right-aligned in the content header on rail layouts.
  final List<Widget>? actions;

  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Scaffold(
        appBar: (title != null || actions != null)
            ? AppBar(
                title: title == null ? null : Text(title!),
                actions: actions,
              )
            : null,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    final extended = context.isDesktop;
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRail(context, extended: extended),
            // Hairline separation instead of rail elevation — the same
            // border language as the AppBar/cards.
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || actions != null)
                    _ContentHeader(title: title, actions: actions),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context, {required bool extended}) {
    final selected = currentIndex >= 0 && currentIndex < destinations.length
        ? currentIndex
        : 0;

    return NavigationRail(
      extended: extended,
      minExtendedWidth: 220,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: selected,
      onDestinationSelected: (index) => destinations[index].onTap(),
      leading: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 24, left: extended ? 8 : 0),
        child: extended
            ? const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AppWordmark(markSize: 26),
                ),
              )
            : const AppLogoMark(size: 28),
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon ?? destination.icon),
            label: Text(destination.label),
            padding: const EdgeInsets.symmetric(vertical: 2),
          ),
      ],
    );
  }
}

/// Flat 64px header row above the content pane on rail layouts — plays the
/// AppBar's role (title + actions) with the same hairline-bottom treatment,
/// without the mobile AppBar chrome.
class _ContentHeader extends StatelessWidget {
  const _ContentHeader({this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          if (actions != null) ...[const SizedBox(width: 16), ...actions!],
        ],
      ),
    );
  }
}
