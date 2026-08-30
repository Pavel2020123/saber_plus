import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import '../core/preferences/app_preferences.dart';
import '../core/preferences/app_preferences_controller.dart';
import '../core/security/session_security.dart';
import '../features/auth/presentation/session_controller.dart';

class SaberPlusApp extends ConsumerWidget {
  const SaberPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionSecurityProvider, (previous, next) {
      if (next == null) return;
      ref.read(sessionSecurityProvider.notifier).clear();
      unawaited(
        ref
            .read(sessionControllerProvider.notifier)
            .invalidateFromOtherDevice(message: next.message),
      );
    });
    final router = ref.watch(appRouterProvider);
    final theme = ref
        .watch(appPreferencesControllerProvider)
        .valueOrNull
        ?.theme;

    return MaterialApp.router(
      title: 'SaberPlus',
      debugShowCheckedModeBanner: false,
      theme: SaberPlusTheme.light,
      darkTheme: SaberPlusTheme.dark,
      themeMode: switch (theme) {
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light || null => ThemeMode.light,
      },
      routerConfig: router,
    );
  }
}
