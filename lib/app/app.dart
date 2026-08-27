import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class SaberPlusApp extends ConsumerWidget {
  const SaberPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SaberPlus',
      debugShowCheckedModeBanner: false,
      theme: SaberPlusTheme.light,
      darkTheme: SaberPlusTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
