import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'helpers/competitive_ranking_fixture.dart';

void main() {
  test('TOP 50 y posición 51 preservan los valores y orden del servidor', () {
    final board = fixtureBoard();
    expect(board.entries.length, 50);
    expect(board.totalParticipants, 60);
    expect(board.entries.first.xp, 1000);
    expect(board.myPosition!.position, 51);
    expect(board.myPosition!.alias, 'Tú');
    expect(() => board.entries.clear(), throwsUnsupportedError);
  });
  test('posición propia dentro del TOP coincide con la entrada', () {
    final json = competitiveFixture();
    final entries = json['ranking'] as List;
    entries[0] = {
      'posicion': 1,
      'alias': 'Tú',
      'xp': 1000,
      'esUsuarioActual': true,
    };
    json['miPosicion'] = entries[0];
    expect(CompetitiveBoard.parse(json).myPosition!.position, 1);
  });
  test('estudiante sin saldo puede carecer de posición en ranking poblado', () {
    expect(
      CompetitiveBoard.parse(competitiveFixture(own: false)).myPosition,
      isNull,
    );
  });
  test('juego integrado sin participantes es distinto de no disponible', () {
    final board = fixtureBoard(state: 'SIN_PARTICIPANTES');
    expect(board.state, CompetitiveRankingState.empty);
    expect(board.totalParticipants, 0);
    expect(board.entries, isEmpty);
    expect(board.myPosition, isNull);
  });
  for (final game in [CompetitiveGame.memory, CompetitiveGame.battles]) {
    test('${game.backendValue} no disponible conserva total null', () {
      final board = fixtureBoard(game: game, state: 'NO_DISPONIBLE');
      expect(board.state, CompetitiveRankingState.unavailable);
      expect(board.totalParticipants, isNull);
      expect(board.entries, isEmpty);
    });
  }
  final malformed = <String, void Function(Map<String, dynamic>)>{
    'total null en juego poblado': (j) => j['totalParticipantes'] = null,
    'total fraccionario': (j) => j['totalParticipantes'] = 60.5,
    'estado desconocido': (j) => j['estado'] = 'OTRO',
    'juego desconocido': (j) => j['juego'] = 'OTRO',
    'temporada cero': (j) => j['temporada'] = 0,
    'temporada string': (j) => j['temporada'] = '2026',
    'limite incorrecto': (j) => j['limite'] = 49,
    'TOP truncado': (j) => (j['ranking'] as List).removeLast(),
    'TOP mayor que 50': (j) =>
        (j['ranking'] as List).add((j['ranking'] as List).first),
    'puesto fraccionario': (j) =>
        (j['ranking'] as List).first['posicion'] = 1.5,
    'XP fraccionario': (j) => (j['ranking'] as List).first['xp'] = 10.5,
    'XP cero': (j) => (j['ranking'] as List).first['xp'] = 0,
    'boolean ausente': (j) =>
        (j['ranking'] as List).first.remove('esUsuarioActual'),
    'alias vacío': (j) => (j['ranking'] as List).first['alias'] = ' ',
    'orden de puestos contradictorio': (j) =>
        (j['ranking'] as List)[1]['posicion'] = 1,
    'orden XP contradictorio': (j) => (j['ranking'] as List)[1]['xp'] = 1001,
    'propio fuera de población': (j) => j['miPosicion']['posicion'] = 61,
    'propio sin marca': (j) => j['miPosicion']['esUsuarioActual'] = false,
    'propio duplicado en TOP': (j) =>
        (j['ranking'] as List).first['esUsuarioActual'] = true,
    'UUID de otro usuario': (j) =>
        (j['ranking'] as List).first['usuarioId'] = 'private-id',
    'metadata privada de board': (j) => j['evidencia'] = 'private',
  };
  for (final entry in malformed.entries) {
    test('rechaza ${entry.key}', () {
      final json = competitiveFixture();
      entry.value(json);
      expect(() => CompetitiveBoard.parse(json), throwsFormatException);
    });
  }
  test('estados vacíos no aceptan datos incompatibles', () {
    final empty = competitiveFixture(state: 'SIN_PARTICIPANTES');
    empty['totalParticipantes'] = null;
    expect(() => CompetitiveBoard.parse(empty), throwsFormatException);
    final unavailable = competitiveFixture(
      game: CompetitiveGame.memory,
      state: 'NO_DISPONIBLE',
    );
    unavailable['totalParticipantes'] = 0;
    expect(() => CompetitiveBoard.parse(unavailable), throwsFormatException);
    expect(
      () => fixtureBoard(game: CompetitiveGame.memory),
      throwsFormatException,
    );
    expect(() => fixtureBoard(state: 'NO_DISPONIBLE'), throwsFormatException);
  });
  test('body no objeto y entradas no objeto fallan sin valores inventados', () {
    for (final raw in [null, [], 'body']) {
      expect(() => CompetitiveBoard.parse(raw), throwsFormatException);
    }
    final json = competitiveFixture();
    json['ranking'] = List<Object?>.from(json['ranking'] as List)..[0] = null;
    expect(() => CompetitiveBoard.parse(json), throwsFormatException);
  });
  test(
    'año sugerido respeta el cambio anual de Bogotá y no zona del dispositivo',
    () {
      expect(
        suggestedCompetitiveSeason(DateTime.parse('2027-01-01T04:59:59Z')),
        2026,
      );
      expect(
        suggestedCompetitiveSeason(DateTime.parse('2027-01-01T05:00:00Z')),
        2027,
      );
      expect(
        suggestedCompetitiveSeason(DateTime.parse('2027-01-01T06:00:00+01:00')),
        2027,
      );
    },
  );
}
