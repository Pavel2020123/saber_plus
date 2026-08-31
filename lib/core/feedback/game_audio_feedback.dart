import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences_controller.dart';

enum GameSound {
  triviaCorrect('audio/trivia_correct.mp3'),
  triviaWrong('audio/trivia_wrong.mp3'),
  triviaCountdown('audio/trivia_countdown.mp3'),
  triviaFinish('audio/trivia_finish.mp3'),
  memoryFlip('audio/memory_flip.mp3'),
  memoryMatch('audio/memory_match.mp3'),
  matchFound('audio/match_found.mp3'),
  matchCountdown('audio/match_countdown.mp3'),
  matchVictory('audio/match_victory.mp3'),
  matchDefeat('audio/match_defeat.mp3'),
  tugPull('audio/tug_pull.mp3'),
  tugRopeStrain('audio/tug_rope_strain.mp3');

  const GameSound(this.assetPath);

  final String assetPath;
}

abstract interface class GameAudioFeedback {
  Future<void> play(GameSound sound);
}

typedef GameSoundAction = Future<void> Function(GameSound sound);

class DeviceGameAudioFeedback implements GameAudioFeedback {
  const DeviceGameAudioFeedback({
    required this.enabled,
    required this.soundAction,
  });

  final bool enabled;
  final GameSoundAction soundAction;

  @override
  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    try {
      await soundAction(sound);
    } on Object {
      // El audio nunca debe interrumpir una partida ni alterar su resultado.
    }
  }
}

final gameAudioFeedbackProvider = Provider<GameAudioFeedback>((ref) {
  final preferences = ref.watch(appPreferencesControllerProvider).valueOrNull;
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return DeviceGameAudioFeedback(
    enabled: preferences?.gameSoundEnabled ?? true,
    soundAction: (sound) => player.play(
      AssetSource(sound.assetPath),
      volume: 0.7,
      mode: PlayerMode.lowLatency,
    ),
  );
});
