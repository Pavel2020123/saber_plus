import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/answer_streak_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incluye el MP3 de éxito dentro de la aplicación', () async {
    final data = await rootBundle.load(
      'assets/audio/answer_streak_success.mp3',
    );

    expect(data.lengthInBytes, greaterThan(0));
  });

  test('reproduce sonido y vibración una sola vez', () async {
    var soundCalls = 0;
    var hapticCalls = 0;
    final feedback = DeviceAnswerStreakFeedback(
      soundEnabled: true,
      vibrationEnabled: true,
      soundAction: () async {
        soundCalls++;
      },
      hapticAction: () async {
        hapticCalls++;
      },
    );

    await feedback.play();

    expect(soundCalls, 1);
    expect(hapticCalls, 1);
  });

  test('respeta las preferencias independientes', () async {
    var soundCalls = 0;
    var hapticCalls = 0;
    final onlySound = DeviceAnswerStreakFeedback(
      soundEnabled: true,
      vibrationEnabled: false,
      soundAction: () async {
        soundCalls++;
      },
      hapticAction: () async {
        hapticCalls++;
      },
    );

    await onlySound.play();

    expect(soundCalls, 1);
    expect(hapticCalls, 0);
  });

  test('un fallo del dispositivo no interrumpe el resultado', () async {
    final feedback = DeviceAnswerStreakFeedback(
      soundEnabled: true,
      vibrationEnabled: true,
      soundAction: () async => throw Exception('audio unavailable'),
      hapticAction: () async => throw Exception('haptics unavailable'),
    );

    await expectLater(feedback.play(), completes);
  });
}
