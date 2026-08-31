import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incluye todos los efectos de juegos declarados', () async {
    for (final sound in GameSound.values) {
      final data = await rootBundle.load('assets/${sound.assetPath}');
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'El audio ${sound.assetPath} debe existir y tener contenido.',
      );
    }
  });

  test(
    'reproduce el efecto solicitado cuando los sonidos están activos',
    () async {
      final played = <GameSound>[];
      final feedback = DeviceGameAudioFeedback(
        enabled: true,
        soundAction: (sound) async => played.add(sound),
      );

      await feedback.play(GameSound.memoryMatch);

      expect(played, [GameSound.memoryMatch]);
    },
  );

  test('no reproduce efectos cuando el estudiante los desactiva', () async {
    var calls = 0;
    final feedback = DeviceGameAudioFeedback(
      enabled: false,
      soundAction: (_) async => calls++,
    );

    await feedback.play(GameSound.triviaCorrect);

    expect(calls, 0);
  });

  test('un error de audio nunca detiene la partida', () async {
    final feedback = DeviceGameAudioFeedback(
      enabled: true,
      soundAction: (_) async => throw Exception('audio unavailable'),
    );

    await expectLater(feedback.play(GameSound.matchVictory), completes);
  });
}
