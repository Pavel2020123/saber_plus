import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/tug_of_war/data/tug_realtime_client.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_online_models.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_of_war_models.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_of_war_providers.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_online_page.dart';

void main() {
  test('construye la ruta del multijugador con filtro de área', () {
    const config = TugOnlineConfig(area: AcademicArea.mathematics);
    final restored = TugOnlineConfig.tryFromUri(
      Uri.parse(config.routeLocation),
    );

    expect(config.routeLocation, contains('area=MATEMATICAS'));
    expect(restored.area, AcademicArea.mathematics);
    expect(
      TugOnlineConfig.tryFromUri(
        Uri.parse('/student/practice/tug-of-war/online?area=INVALIDA'),
      ).area,
      isNull,
    );
  });

  test('interpreta reloj, lado y ganador desde el estado del servidor', () {
    final snapshot = TugOnlineSnapshot.fromJson(
      _snapshotJson(
        status: 'FINALIZADA',
        side: 'B',
        result: 'JUGADOR_B',
        winnerId: 'me',
        ropePosition: -4,
      ),
    );

    expect(snapshot.ropePosition, 4);
    expect(snapshot.winner, TugWinner.player);
    expect(snapshot.rulesVersion, 1);
    expect(snapshot.events, isEmpty);
  });

  test('genera claves UUID distintas e idempotentes para cada respuesta', () {
    final first = createTugIdempotencyKey(Random(1));
    final second = createTugIdempotencyKey(Random(2));
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(first, matches(uuid));
    expect(second, matches(uuid));
    expect(first, isNot(second));
  });

  test(
    'sincroniza cambios y crea el tirón desde la perspectiva del jugador',
    () async {
      final client = _FakeRealtimeClient();
      final controller = TugOnlineController(
        client,
        area: AcademicArea.mathematics,
      );
      client.add(const TugRealtimeConnected());
      await _flush();
      expect(client.matchedArea, AcademicArea.mathematics);

      client.add(
        TugRealtimeState(
          TugOnlineSnapshot.fromJson(
            _snapshotJson(status: 'ACTIVA', version: 2, round: 1),
          ),
        ),
      );
      await _flush();
      expect(controller.state.effect, isNull);

      client.add(const TugRealtimeUpdated('match-1'));
      await _flush();
      expect(client.synchronizedVersion, 2);

      client.add(
        TugRealtimeState(
          TugOnlineSnapshot.fromJson(
            _snapshotJson(
              status: 'ACTIVA',
              version: 4,
              round: 2,
              ropePosition: 2,
              events: [
                {
                  'version': 3,
                  'tipo': 'RONDA_RESUELTA',
                  'datos': {
                    'movimiento': 2,
                    'posicionCuerda': 2,
                    'motivo': 'SOLO_A_CORRECTA',
                    'explicacion': 'Explicación académica.',
                  },
                  'fecha': DateTime.now().toUtc().toIso8601String(),
                },
              ],
            ),
          ),
        ),
      );
      await _flush();

      expect(controller.state.effect?.fromPosition, 0);
      expect(controller.state.effect?.toPosition, 2);
      expect(controller.state.effect?.resolution.ropeDelta, 2);
      expect(
        controller.state.effect?.answerExplanation,
        'Explicación académica.',
      );
      controller.dispose();
    },
  );

  testWidgets('muestra búsqueda y preparación con un cliente inyectado', (
    tester,
  ) async {
    final client = _FakeRealtimeClient(
      onMatchmake: () => _snapshotJson(status: 'BUSCANDO'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tugRealtimeClientFactoryProvider.overrideWithValue(() => client),
        ],
        child: const MaterialApp(
          home: TugOnlinePage(
            config: TugOnlineConfig(area: AcademicArea.mathematics),
          ),
        ),
      ),
    );
    client.add(const TugRealtimeConnected());
    await tester.pump();
    await tester.pump();

    expect(find.text('Buscando un rival…'), findsOneWidget);

    client.add(
      TugRealtimeState(
        TugOnlineSnapshot.fromJson(
          _snapshotJson(status: 'PREPARANDO', rival: true, version: 1),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('¡Rival encontrado!'), findsOneWidget);
    expect(find.byKey(const Key('ready-online-tug')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _FakeRealtimeClient implements TugRealtimeClient {
  _FakeRealtimeClient({this.onMatchmake});

  final Map<String, dynamic> Function()? onMatchmake;
  final _events = StreamController<TugRealtimeEvent>.broadcast();
  AcademicArea? matchedArea;
  int? synchronizedVersion;

  void add(TugRealtimeEvent event) => _events.add(event);

  @override
  Stream<TugRealtimeEvent> get events => _events.stream;

  @override
  void connect() {}

  @override
  Future<void> matchmake(AcademicArea? area) async {
    matchedArea = area;
    final json = onMatchmake?.call();
    if (json != null) add(TugRealtimeState(TugOnlineSnapshot.fromJson(json)));
  }

  @override
  Future<void> synchronize(String matchId, {int? sinceVersion}) async {
    synchronizedVersion = sinceVersion;
  }

  @override
  Future<void> ready(String matchId) async {}

  @override
  Future<void> answer({
    required String matchId,
    required int round,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) async {}

  @override
  Future<void> abandon(String matchId) async {}

  @override
  void dispose() {
    unawaited(_events.close());
  }
}

Map<String, dynamic> _snapshotJson({
  required String status,
  String side = 'A',
  String? result,
  String? winnerId,
  int version = 0,
  int round = 0,
  int ropePosition = 0,
  bool rival = false,
  List<Map<String, dynamic>> events = const [],
}) {
  final now = DateTime.now().toUtc();
  final myPosition = side == 'A' ? ropePosition : -ropePosition;
  return {
    'servidorAhora': now.toIso8601String(),
    'partida': {
      'id': 'match-1',
      'estado': status,
      'resultado': result,
      'area': 'MATEMATICAS',
      'lado': side,
      'version': version,
      'versionReglas': 1,
      'posicionCuerda': ropePosition,
      'posicionDesdeMiLado': myPosition,
      'rondaActual': round,
      'totalPreguntas': 20,
      'listoA': false,
      'listoB': false,
      'rondaIniciaEn': round == 0
          ? null
          : now.subtract(const Duration(seconds: 1)).toIso8601String(),
      'rondaVenceEn': round == 0
          ? null
          : now.add(const Duration(seconds: 9)).toIso8601String(),
      'yo': {'id': 'me', 'nombre': 'Ana', 'fotoPerfil': null},
      'rival': rival || status == 'ACTIVA' || status == 'FINALIZADA'
          ? {'id': 'rival', 'nombre': 'Luis', 'fotoPerfil': null}
          : null,
      'ganadorId': winnerId,
      'yaRespondi': false,
      'pregunta': status == 'ACTIVA'
          ? {
              'id': 'question-1',
              'enunciado': '¿Cuánto es dos más dos?',
              'imagenUrl': null,
              'area': 'MATEMATICAS',
              'tema': 'Aritmética',
              'subtema': 'Suma',
              'opciones': [
                {'id': 'answer-a', 'texto': '4'},
                {'id': 'answer-b', 'texto': '5'},
              ],
              'tiempoLimiteSegundos': 10,
            }
          : null,
    },
    'eventos': events,
  };
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
