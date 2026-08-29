import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences_controller.dart';

abstract interface class AnswerStreakFeedback {
  Future<void> play();
}

typedef HapticAction = Future<void> Function();
typedef SoundAction = Future<void> Function();

class DeviceAnswerStreakFeedback implements AnswerStreakFeedback {
  const DeviceAnswerStreakFeedback({
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.soundAction,
    this.hapticAction = HapticFeedback.lightImpact,
  });

  final bool vibrationEnabled;
  final bool soundEnabled;
  final HapticAction hapticAction;
  final SoundAction soundAction;

  @override
  Future<void> play() async {
    await Future.wait([
      if (soundEnabled) _runSafely(soundAction),
      if (vibrationEnabled) _runSafely(hapticAction),
    ]);
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // El feedback no debe impedir que el estudiante vea su resultado.
    }
  }
}

final answerStreakFeedbackProvider = Provider<AnswerStreakFeedback>((ref) {
  final preferences = ref.watch(appPreferencesControllerProvider).valueOrNull;
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return DeviceAnswerStreakFeedback(
    vibrationEnabled: preferences?.answerStreakVibrationEnabled ?? true,
    soundEnabled: preferences?.answerStreakSoundEnabled ?? true,
    soundAction: () => player.play(
      AssetSource('audio/answer_streak_success.mp3'),
      volume: 0.65,
    ),
  );
});
