import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';

Map<String, dynamic> competitiveFixture({
  CompetitiveGame game = CompetitiveGame.trivia,
  int season = 2026,
  String state = 'CON_PARTICIPANTES',
  int count = 60,
  bool own = true,
}) => {
  'juego': game.backendValue,
  'temporada': season,
  'limite': 50,
  'estado': state,
  'totalParticipantes': state == 'NO_DISPONIBLE'
      ? null
      : state == 'SIN_PARTICIPANTES'
      ? 0
      : count,
  'ranking': state != 'CON_PARTICIPANTES'
      ? <Map<String, dynamic>>[]
      : List.generate(
          count < 50 ? count : 50,
          (i) => <String, dynamic>{
            'posicion': i + 1,
            'alias': 'Estudiante ficticio ${i + 1}',
            'xp': 1000 - i,
            'esUsuarioActual': false,
          },
        ),
  'miPosicion': state == 'CON_PARTICIPANTES' && own
      ? <String, dynamic>{
          'posicion': 51,
          'alias': 'Tú',
          'xp': 950,
          'esUsuarioActual': true,
        }
      : null,
};

CompetitiveBoard fixtureBoard({
  CompetitiveGame game = CompetitiveGame.trivia,
  int season = 2026,
  String state = 'CON_PARTICIPANTES',
}) => CompetitiveBoard.parse(
  competitiveFixture(game: game, season: season, state: state),
);
