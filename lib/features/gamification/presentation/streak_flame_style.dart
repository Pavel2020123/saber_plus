import 'package:flutter/material.dart';

import '../domain/gamification_models.dart';

enum StreakFlameState { active, frozen, lost }

class StreakFlameStyle {
  const StreakFlameStyle({
    required this.state,
    required this.color,
    required this.levelLabel,
    required this.minimumDays,
  });

  final StreakFlameState state;
  final Color color;
  final String levelLabel;
  final int minimumDays;

  bool get burns => state == StreakFlameState.active;

  String get statusLabel => switch (state) {
    StreakFlameState.active => 'Llama $levelLabel',
    StreakFlameState.frozen => 'Llama congelada',
    StreakFlameState.lost => 'Llama apagada',
  };

  factory StreakFlameStyle.fromStreak(StudyStreak streak) {
    if (streak.current <= 0) {
      return const StreakFlameStyle(
        state: StreakFlameState.lost,
        color: Color(0xFF9CA3AF),
        levelLabel: 'apagada',
        minimumDays: 0,
      );
    }
    if (!streak.activeToday) {
      return const StreakFlameStyle(
        state: StreakFlameState.frozen,
        color: Color(0xFF38BDF8),
        levelLabel: 'congelada',
        minimumDays: 0,
      );
    }
    if (streak.current >= 50) {
      return const StreakFlameStyle(
        state: StreakFlameState.active,
        color: Color(0xFF06B6D4),
        levelLabel: 'legendaria',
        minimumDays: 50,
      );
    }
    if (streak.current >= 40) {
      return const StreakFlameStyle(
        state: StreakFlameState.active,
        color: Color(0xFF3B82F6),
        levelLabel: 'azul',
        minimumDays: 40,
      );
    }
    if (streak.current >= 30) {
      return const StreakFlameStyle(
        state: StreakFlameState.active,
        color: Color(0xFFA855F7),
        levelLabel: 'violeta',
        minimumDays: 30,
      );
    }
    if (streak.current >= 20) {
      return const StreakFlameStyle(
        state: StreakFlameState.active,
        color: Color(0xFFEF4444),
        levelLabel: 'roja',
        minimumDays: 20,
      );
    }
    if (streak.current >= 10) {
      return const StreakFlameStyle(
        state: StreakFlameState.active,
        color: Color(0xFFFBBF24),
        levelLabel: 'dorada',
        minimumDays: 10,
      );
    }
    return const StreakFlameStyle(
      state: StreakFlameState.active,
      color: Color(0xFFFF7A00),
      levelLabel: 'naranja',
      minimumDays: 1,
    );
  }
}
