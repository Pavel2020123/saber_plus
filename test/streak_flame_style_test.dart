import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/domain/gamification_models.dart';
import 'package:saber_plus/features/gamification/presentation/streak_flame_style.dart';

void main() {
  test('cambia el nivel visual cada diez días', () {
    expect(_activeStyle(9).levelLabel, 'naranja');
    expect(_activeStyle(10).levelLabel, 'dorada');
    expect(_activeStyle(20).levelLabel, 'roja');
    expect(_activeStyle(30).levelLabel, 'violeta');
    expect(_activeStyle(40).levelLabel, 'azul');
    expect(_activeStyle(50).levelLabel, 'legendaria');
  });

  test('congela una racha pendiente y apaga una racha perdida', () {
    final frozen = StreakFlameStyle.fromStreak(
      const StudyStreak(current: 12, best: 12, activeToday: false),
    );
    final lost = StreakFlameStyle.fromStreak(StudyStreak.empty);

    expect(frozen.state, StreakFlameState.frozen);
    expect(frozen.burns, isFalse);
    expect(lost.state, StreakFlameState.lost);
    expect(lost.burns, isFalse);
  });
}

StreakFlameStyle _activeStyle(int days) => StreakFlameStyle.fromStreak(
  StudyStreak(current: days, best: days, activeToday: true),
);
