import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:saber_plus/core/widgets/academic_option_content.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/tug_of_war/data/tug_realtime_client.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_online_models.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_of_war_models.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_of_war_providers.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_online_page.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/animation/tug_arena.dart';

void main() {
  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'opciones online ilustradas caben en su borde $width/$scale',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 2000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const paths = [
            '/recursos/editoriales/11111111-1111-4111-8111-111111111111',
            '/recursos/editoriales/22222222-2222-4222-8222-222222222222',
          ];
          final images = (await tester.runAsync(() async {
            final result = <ui.Image>[];
            for (final size in [const Size(160, 80), const Size(80, 160)]) {
              final recorder = ui.PictureRecorder();
              Canvas(
                recorder,
              ).drawRect(Offset.zero & size, Paint()..color = Colors.blue);
              final picture = recorder.endRecording();
              result.add(
                await picture.toImage(size.width.toInt(), size.height.toInt()),
              );
              picture.dispose();
            }
            return result;
          }))!;
          addTearDown(() {
            for (final image in images) {
              image.dispose();
            }
          });
          final payload = _snapshotJson(status: 'ACTIVA', round: 1, version: 1);
          final question = (payload['partida'] as Map)['pregunta'] as Map;
          question['enunciado'] =
              '¿Qué figura tiene el ancho doble de su altura?';
          question['opciones'] = [
            {
              'id': 'blue',
              'texto': 'Rectángulo azul horizontal',
              'imagenUrl': paths[0],
            },
            {
              'id': 'orange',
              'texto': 'Rectángulo naranja vertical',
              'imagenUrl': paths[1],
            },
          ];
          final client = _FakeRealtimeClient(onMatchmake: () => payload);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                tugRealtimeClientFactoryProvider.overrideWithValue(
                  () => client,
                ),
                editorialImageProvider(
                  paths[0],
                ).overrideWith((ref) async => images[0]),
                editorialImageProvider(
                  paths[1],
                ).overrideWith((ref) async => images[1]),
              ],
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const TugOnlinePage(config: TugOnlineConfig()),
              ),
            ),
          );
          client.add(const TugRealtimeConnected());
          for (var frame = 0; frame < 8; frame++) {
            await tester.pump();
          }
          expect(
            find.descendant(
              of: find.byType(AcademicOptionContent),
              matching: find.byType(RawImage),
            ),
            findsNWidgets(2),
          );
          for (final id in ['blue', 'orange']) {
            final button = find.byKey(Key('tug-online-answer-$id'));
            final material = find
                .descendant(of: button, matching: find.byType(Material))
                .first;
            final border = tester.widget<Material>(material).shape!;
            final bounds = tester.getRect(material);
            final outline = border.getOuterPath(Offset.zero & bounds.size);
            final content = find.descendant(
              of: button,
              matching: find.byType(AcademicOptionContent),
            );
            for (final part in [
              find.descendant(of: content, matching: find.byType(Text)),
              find.descendant(of: content, matching: find.byType(RawImage)),
            ]) {
              final rect = tester
                  .getRect(part)
                  .shift(-bounds.topLeft)
                  .deflate(1);
              for (final point in [
                rect.topLeft,
                rect.topRight,
                rect.bottomLeft,
                rect.bottomRight,
              ]) {
                expect(
                  outline.contains(point),
                  isTrue,
                  reason: '$id: $rect fuera de $border a $width/$scale',
                );
              }
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  test('transporte Socket.IO recibe estado con offset de recuperación', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final connections = <WebSocket>[];
    final payload = _snapshotJson(status: 'PREPARANDO', rival: true);
    final requests = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      connections.add(socket);
      socket.add(
        '0${jsonEncode({'sid': 'test-engine', 'upgrades': <String>[], 'pingInterval': 25000, 'pingTimeout': 20000})}',
      );
      socket.listen((packet) {
        if (packet is String && packet.startsWith('40/tira-afloja,')) {
          socket.add(
            '40/tira-afloja,${jsonEncode({'sid': 'test-socket', 'pid': 'test-recovery'})}',
          );
          socket.add(
            '42/tira-afloja,${jsonEncode(['tira:estado', payload, 'recovery-offset'])}',
          );
        }
      });
    });
    final dio = Dio();
    final client = SocketTugRealtimeClient(
      dio,
      apiBaseUrl: 'http://127.0.0.1:${server.port}',
      accessToken: 'test-only',
    );
    try {
      final result = client.events.firstWhere(
        (event) => event is TugRealtimeState || event is TugRealtimeFailure,
      );
      client.connect();
      final event = await result.timeout(const Duration(seconds: 5));
      expect(event, isA<TugRealtimeState>());
      expect((event as TugRealtimeState).snapshot.id, 'match-1');
      expect(event.snapshot.rival?.id, 'rival');
    } finally {
      client.dispose();
      dio.close();
      for (final socket in connections) {
        await socket.close();
      }
      await requests.cancel();
      await server.close(force: true);
    }
  });

  test(
    'lee eventos con offset de recuperación sin perder reloj ni referencias',
    () {
      final payload = _snapshotJson(status: 'PREPARANDO', rival: true);
      for (final event in <Object>[
        payload,
        [payload, 'recovery-offset'],
      ]) {
        final snapshot = TugOnlineSnapshot.fromJson(
          tugRealtimeEventObject(event),
        );
        expect(snapshot.status, TugOnlineMatchStatus.preparing);
        expect(snapshot.id, 'match-1');
        expect(snapshot.rival?.id, 'rival');
        expect(snapshot.serverOffset.inSeconds.abs(), lessThan(2));
      }
      final update = {'partidaId': 'match-1'};
      expect(tugRealtimeEventObject([update, 'offset']), update);
      final presence = {'usuarioId': 'B', 'conectado': false};
      expect(tugRealtimeEventObject([presence, 'offset']), presence);
      for (final invalid in <Object?>[
        null,
        [],
        [payload],
        [payload, 1],
        [payload, 'offset', 'extra'],
      ]) {
        expect(tugRealtimeEventObject(invalid), isEmpty);
      }
      expect(
        () => TugOnlineSnapshot.fromJson(
          tugRealtimeEventObject([
            {'partida': {}},
            'offset',
          ]),
        ),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test(
    'referencias A/B permiten ganador y presencia sin identidad privada',
    () async {
      final client = _FakeRealtimeClient();
      final controller = TugOnlineController(client);
      for (final side in ['A', 'B']) {
        final other = side == 'A' ? 'B' : 'A';
        final payload = _snapshotJson(
          status: 'FINALIZADA',
          side: side,
          result: 'JUGADOR_$side',
          winnerId: side,
          rival: true,
        );
        final match = payload['partida'] as Map<String, dynamic>;
        match['yo'] = {
          'id': side,
          'nombre': 'Jugador $side',
          'fotoPerfil': null,
        };
        match['rival'] = {
          'id': other,
          'nombre': 'Jugador $other',
          'fotoPerfil': null,
        };
        final snapshot = TugOnlineSnapshot.fromJson(payload);
        expect(snapshot.winner, TugWinner.player);
        expect(snapshot.me.avatarUrl, isNull);
        expect(snapshot.rival?.avatarUrl, isNull);
        expect(snapshot.rival?.name, 'Jugador $other');
        client.add(TugRealtimeState(snapshot));
        await _flush();
        client.add(TugRealtimePresence(userId: other, connected: false));
        await _flush();
        expect(controller.state.rivalConnected, isFalse);
        client.add(TugRealtimePresence(userId: other, connected: true));
        await _flush();
        expect(controller.state.rivalConnected, isTrue);
        match['ganadorId'] = other;
        expect(TugOnlineSnapshot.fromJson(payload).winner, TugWinner.cpu);
      }
      controller.dispose();
    },
  );

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

  testWidgets('solo confirma respuestas y reacciones recibidas del servidor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeRealtimeClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tugRealtimeClientFactoryProvider.overrideWithValue(() => client),
        ],
        child: const MaterialApp(
          home: TugOnlinePage(config: TugOnlineConfig()),
        ),
      ),
    );
    client.add(const TugRealtimeConnected());
    client.add(
      TugRealtimeState(
        TugOnlineSnapshot.fromJson(
          _snapshotJson(status: 'ACTIVA', round: 1, version: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    var arena = tester.widget<TugArena>(find.byType(TugArena));
    expect(arena.opponentLabel, 'RIVAL');
    expect(arena.animationCue, isNull);
    expect(arena.playerAnswered, isFalse);

    await tester.tap(find.byKey(const Key('tug-online-answer-answer-a')));
    await tester.pump();
    expect(
      find.text('Enviando respuesta… Espera la confirmación.'),
      findsOneWidget,
    );
    arena = tester.widget<TugArena>(find.byType(TugArena));
    expect(arena.playerAnswered, isFalse);
    expect(arena.animationCue, isNull);

    client.add(
      TugRealtimeState(
        TugOnlineSnapshot.fromJson(
          _snapshotJson(status: 'ACTIVA', round: 1, version: 2, answered: true),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Respuesta confirmada. Esperando el resultado de la ronda…'),
      findsOneWidget,
    );
    arena = tester.widget<TugArena>(find.byType(TugArena));
    expect(arena.playerAnswered, isTrue);
    expect(arena.animationCue, isNull);

    client.add(const TugRealtimeDisconnected());
    await tester.pump();
    expect(find.textContaining('Reconectando… El tiempo'), findsOneWidget);
    expect(tester.widget<TugArena>(find.byType(TugArena)).paused, isTrue);
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
  bool answered = false,
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
      'yaRespondi': answered,
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
