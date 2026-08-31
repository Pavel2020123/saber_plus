import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/answer_streak_feedback.dart';
import '../feedback/game_audio_feedback.dart';
import 'app_preferences.dart';
import 'app_preferences_controller.dart';

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(
          onRetry: () => ref.invalidate(appPreferencesControllerProvider),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Elige cómo quieres ver SaberPlus en este dispositivo.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemePreference>(
                key: const Key('theme-selector'),
                segments: const [
                  ButtonSegment(
                    value: ThemePreference.system,
                    icon: Icon(Icons.settings_suggest_outlined),
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(
                    value: ThemePreference.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Claro'),
                  ),
                  ButtonSegment(
                    value: ThemePreference.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Oscuro'),
                  ),
                ],
                selected: {value.theme},
                onSelectionChanged: (selection) => _run(
                  context,
                  () => ref
                      .read(appPreferencesControllerProvider.notifier)
                      .setTheme(selection.first),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value.theme == ThemePreference.system
                  ? 'SaberPlus cambiará automáticamente cuando el teléfono use modo claro u oscuro.'
                  : 'Esta elección se mantendrá aunque cambie la apariencia del teléfono.',
              key: const Key('theme-preference-description'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              'Recordatorio de estudio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('daily-reminder-switch'),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Recordatorio diario'),
                    subtitle: const Text(
                      'Recibe una notificación local para mantener tu rutina.',
                    ),
                    value: value.reminderEnabled,
                    onChanged: (enabled) =>
                        _changeReminder(context, ref, enabled),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('daily-reminder-time'),
                    enabled: value.reminderEnabled,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Hora del recordatorio'),
                    subtitle: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(
                          hour: value.reminderHour,
                          minute: value.reminderMinute,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: value.reminderEnabled
                        ? () => _pickTime(context, ref, value)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El permiso se solicita únicamente al activar el recordatorio. '
              'La hora se guarda en este dispositivo y puedes desactivarla cuando quieras.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              'Sonidos de juegos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('game-sound-switch'),
                    secondary: const Icon(Icons.sports_esports_outlined),
                    title: const Text('Efectos durante las partidas'),
                    subtitle: const Text(
                      'Aciertos, cartas, cuenta regresiva y resultados.',
                    ),
                    value: value.gameSoundEnabled,
                    onChanged: (enabled) => _run(
                      context,
                      () => ref
                          .read(appPreferencesControllerProvider.notifier)
                          .setGameSoundEnabled(enabled),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('preview-game-sound'),
                    enabled: value.gameSoundEnabled,
                    leading: const Icon(Icons.play_circle_outline_rounded),
                    title: const Text('Probar sonido de juego'),
                    subtitle: const Text('Reproduce el sonido de un acierto.'),
                    onTap: value.gameSoundEnabled
                        ? () => _previewGameSound(context, ref)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Feedback de aciertos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('answer-streak-sound-switch'),
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: const Text('Sonido en rachas'),
                    subtitle: const Text(
                      'Reproduce un sonido breve al confirmar el logro.',
                    ),
                    value: value.answerStreakSoundEnabled,
                    onChanged: (enabled) => _run(
                      context,
                      () => ref
                          .read(appPreferencesControllerProvider.notifier)
                          .setAnswerStreakSoundEnabled(enabled),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('answer-streak-vibration-switch'),
                    secondary: const Icon(Icons.vibration_rounded),
                    title: const Text('Vibración en rachas'),
                    subtitle: const Text(
                      'Una vibración corta al conseguir 3 o más respuestas correctas seguidas.',
                    ),
                    value: value.answerStreakVibrationEnabled,
                    onChanged: (enabled) => _run(
                      context,
                      () => ref
                          .read(appPreferencesControllerProvider.notifier)
                          .setAnswerStreakVibrationEnabled(enabled),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('preview-answer-streak-feedback'),
                    enabled:
                        value.answerStreakSoundEnabled ||
                        value.answerStreakVibrationEnabled,
                    leading: const Icon(Icons.play_circle_outline_rounded),
                    title: const Text('Probar feedback'),
                    subtitle: const Text(
                      'Escucha el sonido y comprueba la vibración ahora.',
                    ),
                    onTap:
                        value.answerStreakSoundEnabled ||
                            value.answerStreakVibrationEnabled
                        ? () => _previewFeedback(context, ref)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeReminder(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref
          .read(appPreferencesControllerProvider.notifier)
          .setReminderEnabled(enabled);
    } on NotificationPermissionDenied {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitas permitir las notificaciones para activar el recordatorio.',
          ),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      _showSaveError(context);
    }
  }

  Future<void> _previewFeedback(BuildContext context, WidgetRef ref) async {
    await ref.read(answerStreakFeedbackProvider).play();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prueba de racha reproducida.')),
    );
  }

  Future<void> _previewGameSound(BuildContext context, WidgetRef ref) async {
    await ref.read(gameAudioFeedbackProvider).play(GameSound.triviaCorrect);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prueba de juego reproducida.')),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AppPreferences preferences,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: preferences.reminderHour,
        minute: preferences.reminderMinute,
      ),
      helpText: 'Hora del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (selected == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(appPreferencesControllerProvider.notifier)
          .setReminderTime(hour: selected.hour, minute: selected.minute),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on Object {
      if (context.mounted) _showSaveError(context);
    }
  }

  void _showSaveError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No pudimos guardar la preferencia. Intenta nuevamente.'),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.settings_backup_restore_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('No pudimos cargar tus preferencias.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
