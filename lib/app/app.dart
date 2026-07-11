import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

/// Lets any part of the app change the active [ThemeMode] at runtime —
/// backs the manual light/dark override toggle described in README
/// Section 5.2. Defaults to following the system setting.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

/// Root widget of the Dispatchr app: wires up light/dark theming from the
/// design tokens in README Section 5.1 and hosts the app's navigation.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          routerConfig: router,
        );
      },
    );
  }
}
