import 'dart:math';

import '../../../academic/domain/academic_models.dart';

enum TugCpuDifficulty {
  training(
    'entrenamiento',
    'Entrenamiento',
    'Un rival paciente para aprender las reglas.',
    0.56,
    4200,
    7800,
    0.08,
  ),
  balanced(
    'equilibrado',
    'Equilibrado',
    'Buen ritmo sin exigir respuestas perfectas.',
    0.72,
    2800,
    6000,
    0.04,
  ),
  challenge(
    'desafio',
    'Desafío',
    'Responde rápido y suele acertar.',
    0.86,
    1500,
    4300,
    0.02,
  );

  const TugCpuDifficulty(
    this.queryValue,
    this.label,
    this.description,
    this.accuracy,
    this.minimumResponseMilliseconds,
    this.maximumResponseMilliseconds,
    this.timeoutProbability,
  );

  final String queryValue;
  final String label;
  final String description;
  final double accuracy;
  final int minimumResponseMilliseconds;
  final int maximumResponseMilliseconds;
  final double timeoutProbability;

  static TugCpuDifficulty? tryFromQuery(String? value) {
    for (final difficulty in values) {
      if (difficulty.queryValue == value) return difficulty;
    }
    return null;
  }
}

class TugOfWarConfig {
  const TugOfWarConfig({required this.areas, required this.cpuDifficulty});

  final List<AcademicArea> areas;
  final TugCpuDifficulty cpuDifficulty;

  bool get isMixed => areas.length > 1;

  String get routeLocation => Uri(
    path: '/student/practice/tug-of-war/play',
    queryParameters: {
      'areas': areas.map((area) => area.backendValue).join(','),
      'rival': cpuDifficulty.queryValue,
    },
  ).toString();

  static TugOfWarConfig? tryFromUri(Uri uri) {
    final rawAreas = uri.queryParameters['areas'];
    final difficulty = TugCpuDifficulty.tryFromQuery(
      uri.queryParameters['rival'],
    );
    if (rawAreas == null || difficulty == null) return null;
    try {
      final areas = rawAreas
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(AcademicArea.fromBackend)
          .toSet()
          .toList(growable: false);
      if (areas.isEmpty) return null;
      return TugOfWarConfig(areas: areas, cpuDifficulty: difficulty);
    } on Object {
      return null;
    }
  }
}

class TugOnlineConfig {
  const TugOnlineConfig({this.area});

  final AcademicArea? area;

  String get routeLocation => Uri(
    path: '/student/practice/tug-of-war/online',
    queryParameters: {if (area case final value?) 'area': value.backendValue},
  ).toString();

  static TugOnlineConfig tryFromUri(Uri uri) {
    final rawArea = uri.queryParameters['area'];
    if (rawArea == null || rawArea.isEmpty) return const TugOnlineConfig();
    try {
      return TugOnlineConfig(area: AcademicArea.fromBackend(rawArea));
    } on Object {
      return const TugOnlineConfig();
    }
  }
}

class TugCpuTurn {
  const TugCpuTurn({
    required this.isCorrect,
    required this.responseMilliseconds,
  });

  /// `null` representa que el rival dejó vencer el tiempo.
  final bool? isCorrect;
  final int responseMilliseconds;

  factory TugCpuTurn.random(TugCpuDifficulty difficulty, Random random) {
    final responseRange =
        difficulty.maximumResponseMilliseconds -
        difficulty.minimumResponseMilliseconds;
    final responseMilliseconds =
        difficulty.minimumResponseMilliseconds +
        random.nextInt(responseRange + 1);
    if (random.nextDouble() < difficulty.timeoutProbability) {
      return const TugCpuTurn(isCorrect: null, responseMilliseconds: 10000);
    }
    return TugCpuTurn(
      isCorrect: random.nextDouble() < difficulty.accuracy,
      responseMilliseconds: responseMilliseconds,
    );
  }
}

enum TugRoundOutcome { strongPlayer, quickPlayer, neutral, quickCpu, strongCpu }

class TugRoundResolution {
  const TugRoundResolution({
    required this.outcome,
    required this.ropeDelta,
    required this.title,
    required this.explanation,
  });

  final TugRoundOutcome outcome;

  /// Positivo acerca la cuerda al jugador; negativo favorece al rival.
  final int ropeDelta;
  final String title;
  final String explanation;

  static TugRoundResolution resolve({
    required bool? playerCorrect,
    required int? playerResponseMilliseconds,
    required bool? cpuCorrect,
    required int? cpuResponseMilliseconds,
    int tieToleranceMilliseconds = 200,
  }) {
    if (playerCorrect == true && cpuCorrect != true) {
      return const TugRoundResolution(
        outcome: TugRoundOutcome.strongPlayer,
        ropeDelta: 2,
        title: '¡Tirón fuerte para ti!',
        explanation: 'Acertaste y el rival falló o dejó vencer el tiempo.',
      );
    }
    if (playerCorrect != true && cpuCorrect == true) {
      return const TugRoundResolution(
        outcome: TugRoundOutcome.strongCpu,
        ropeDelta: -2,
        title: 'El rival dio un tirón fuerte',
        explanation: 'El rival acertó y tú fallaste o se terminó tu tiempo.',
      );
    }
    if (playerCorrect == true && cpuCorrect == true) {
      final playerTime = playerResponseMilliseconds ?? 10000;
      final cpuTime = cpuResponseMilliseconds ?? 10000;
      final difference = playerTime - cpuTime;
      if (difference.abs() <= tieToleranceMilliseconds) {
        return const TugRoundResolution(
          outcome: TugRoundOutcome.neutral,
          ropeDelta: 0,
          title: 'Empate de velocidad',
          explanation: 'Los dos acertaron prácticamente al mismo tiempo.',
        );
      }
      if (difference < 0) {
        return const TugRoundResolution(
          outcome: TugRoundOutcome.quickPlayer,
          ropeDelta: 1,
          title: 'Fuiste más rápido',
          explanation: 'Ambos acertaron, pero respondiste primero.',
        );
      }
      return const TugRoundResolution(
        outcome: TugRoundOutcome.quickCpu,
        ropeDelta: -1,
        title: 'El rival fue más rápido',
        explanation: 'Ambos acertaron, pero el rival respondió primero.',
      );
    }
    return const TugRoundResolution(
      outcome: TugRoundOutcome.neutral,
      ropeDelta: 0,
      title: 'La cuerda no se mueve',
      explanation: 'Ninguno acertó. La siguiente pregunta sigue igualada.',
    );
  }
}

enum TugWinner { player, cpu, draw }

class TugMatchProgress {
  const TugMatchProgress({
    this.ropePosition = 0,
    this.roundsPlayed = 0,
    this.playerCorrectAnswers = 0,
    this.cpuCorrectAnswers = 0,
  });

  static const winningPosition = 4;

  final int ropePosition;
  final int roundsPlayed;
  final int playerCorrectAnswers;
  final int cpuCorrectAnswers;

  TugWinner? get winner => switch (ropePosition) {
    >= winningPosition => TugWinner.player,
    <= -winningPosition => TugWinner.cpu,
    _ => null,
  };

  TugMatchProgress apply({
    required TugRoundResolution resolution,
    required bool? playerCorrect,
    required bool? cpuCorrect,
  }) => TugMatchProgress(
    ropePosition: (ropePosition + resolution.ropeDelta).clamp(
      -winningPosition,
      winningPosition,
    ),
    roundsPlayed: roundsPlayed + 1,
    playerCorrectAnswers:
        playerCorrectAnswers + (playerCorrect == true ? 1 : 0),
    cpuCorrectAnswers: cpuCorrectAnswers + (cpuCorrect == true ? 1 : 0),
  );

  TugWinner winnerWhenQuestionsEnd() => switch (ropePosition) {
    > 0 => TugWinner.player,
    < 0 => TugWinner.cpu,
    _ => TugWinner.draw,
  };
}
