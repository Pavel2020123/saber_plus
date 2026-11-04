import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/environment.dart';
import 'core/config/presentation_mode.dart';
import 'features/auth/presentation/session_controller.dart';

/// Separate presentation entry point. Never authenticates against the API.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  validatePresentationConfig(AppConfig.current);
  // This container lives for the lifetime of the presentation application.
  final container = ProviderContainer(
    overrides: [presentationModeProvider.overrideWithValue(true)],
  );
  container.read(sessionControllerProvider.notifier).enterDemo();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SaberPlusApp(),
    ),
  );
}

void validatePresentationConfig(AppConfig config) {
  config.validate();
  if (config.environment != AppEnvironment.dev || !config.demoMode) {
    throw StateError('La presentación requiere APP_ENV=dev y DEMO_MODE=true.');
  }
}
