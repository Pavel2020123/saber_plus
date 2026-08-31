import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_models.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_repository.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_duel_providers.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_page.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';

void main() {
  testWidgets('la pantalla usa puntaje y cierre confirmados por el servidor', (
    tester,
  ) async {
    final audio = _RecordingAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          triviaRushRepositoryProvider.overrideWithValue(
            _AuthoritativeRepository(),
          ),
          gameAudioFeedbackProvider.overrideWithValue(audio),
        ],
        child: const MaterialApp(
          home: TriviaRushPage(
            config: TriviaRushConfig(
              areas: [AcademicArea.mathematics],
              duration: TriviaRushDuration.quick,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('250 pts'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trivia-answer-answer-a')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.byKey(const Key('trivia-result-view')), findsOneWidget);
    expect(find.text('700 puntos'), findsOneWidget);
    expect(audio.played, [GameSound.triviaCorrect, GameSound.triviaFinish]);
  });

  testWidgets('el duelo vincula el récord con el intento confirmado', (
    tester,
  ) async {
    final ghosts = _RecordingGhostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          triviaRushRepositoryProvider.overrideWithValue(
            _AuthoritativeRepository(),
          ),
          ghostDuelRepositoryProvider.overrideWithValue(ghosts),
          ghostDuelUserIdProvider.overrideWithValue('student-1'),
          gameAudioFeedbackProvider.overrideWithValue(_RecordingAudio()),
        ],
        child: const MaterialApp(
          home: TriviaRushPage(
            ghostMode: true,
            config: TriviaRushConfig(
              areas: [AcademicArea.mathematics],
              duration: TriviaRushDuration.quick,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('trivia-answer-answer-a')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(
      ghosts.saved?.sourceAttemptId,
      '00000000-0000-4000-8000-000000000001',
    );
    expect(ghosts.saved?.score, 700);
  });
}

class _RecordingGhostRepository implements GhostDuelRepository {
  GhostRun? saved;

  @override
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  }) async => null;

  @override
  Future<GhostSaveResult> saveIfBetter(GhostRun run) async {
    saved = run;
    return GhostSaveResult(outcome: GhostDuelOutcome.firstRecord, bestRun: run);
  }
}

class _AuthoritativeRepository
    implements TriviaRushRepository, AuthoritativeTriviaRushRepository {
  final TriviaRushServerState active = TriviaRushServerState.fromJson(
    _state(status: 'ACTIVO', points: 250, includeQuestion: true),
  );
  final TriviaRushServerState finished = TriviaRushServerState.fromJson(
    _state(status: 'FINALIZADO', points: 700, includeQuestion: false),
  );

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async =>
      _session(active);

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async => TriviaRushAnswerEvaluation(
    questionId: questionId,
    isCorrect: true,
    correctAnswerId: answerId,
    explanation: 'El servidor confirmó la suma.',
    serverState: finished,
  );

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async => TriviaRushBoosterActivation(serverState: active);

  @override
  Future<TriviaRushSession> synchronize(String attemptId) async =>
      _session(active);

  @override
  Future<TriviaRushSession> finish(String attemptId) async =>
      _session(finished);

  @override
  Future<void> abandon(String attemptId) async {}

  TriviaRushSession _session(TriviaRushServerState state) {
    final question = state.currentQuestion;
    return TriviaRushSession(
      attemptId: state.attemptId,
      questions: question == null ? const [] : [question],
      serverState: state,
    );
  }
}

class _RecordingAudio implements GameAudioFeedback {
  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);
}

Map<String, dynamic> _state({
  required String status,
  required int points,
  required bool includeQuestion,
}) => {
  'servidorAhora': '2026-08-31T10:00:00.000Z',
  'intento': {
    'id': '00000000-0000-4000-8000-000000000001',
    'estado': status,
    'versionReglas': 1,
    'areas': ['MATEMATICAS'],
    'duracionBaseSegundos': 60,
    'tiempoExtraSegundos': 0,
    'iniciadoEn': '2026-08-31T10:00:00.000Z',
    'venceEn': '2099-08-31T10:01:00.000Z',
    'finalizadoEn': status == 'ACTIVO' ? null : '2026-08-31T10:00:20.000Z',
    'asistido': false,
    'marcador': {
      'puntaje': points,
      'comboActual': status == 'ACTIVO' ? 2 : 3,
      'mejorCombo': status == 'ACTIVO' ? 2 : 3,
      'respuestasCorrectas': status == 'ACTIVO' ? 2 : 3,
      'respuestasIncorrectas': 0,
      'preguntasSaltadas': 0,
    },
    'progreso': {
      'indiceActual': status == 'ACTIVO' ? 2 : 3,
      'respondidas': status == 'ACTIVO' ? 2 : 3,
      'totalPreguntas': 3,
    },
    'potenciadoresActivos': {
      'escudoCombo': false,
      'segundaOportunidad': false,
      'opcionesEliminadas': <String>[],
    },
    'pregunta': includeQuestion
        ? {
            'id': 'question-1',
            'enunciado': '¿Cuánto es dos más dos?',
            'imagenUrl': null,
            'contexto': null,
            'dificultad': 'BASICO',
            'area': 'MATEMATICAS',
            'tema': 'Aritmética',
            'subtema': 'Suma',
            'subtemaId': 'sums',
            'opciones': [
              {'id': 'answer-a', 'texto': '4'},
              {'id': 'answer-b', 'texto': '5'},
            ],
          }
        : null,
    'resultado': status == 'ACTIVO'
        ? null
        : {'diagnostico': <Map<String, dynamic>>[]},
  },
};
