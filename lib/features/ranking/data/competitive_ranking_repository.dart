import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/competitive_ranking_models.dart';

abstract interface class CompetitiveRankingRepository {
  Future<CompetitiveBoard> load({
    required CompetitiveGame game,
    required int season,
  });
}

class RemoteCompetitiveRankingRepository
    implements CompetitiveRankingRepository {
  RemoteCompetitiveRankingRepository(this._dio);
  final Dio _dio;
  @override
  Future<CompetitiveBoard> load({
    required CompetitiveGame game,
    required int season,
  }) async {
    if (season < 1 || season > 9999) {
      throw const ApiError(
        code: '400',
        message: 'Indica un año entre 1 y 9999.',
      );
    }
    try {
      final response = await _dio.get<Object?>(
        '/ranking/competitivo',
        queryParameters: {'juego': game.backendValue, 'temporada': season},
      );
      final board = CompetitiveBoard.parse(response.data);
      if (board.game != game || board.season != season) {
        throw const FormatException();
      }
      return board;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      // Reuse the application's error type, but never display a remote body.
      throw ApiError(
        code: status?.toString() ?? 'network_unavailable',
        message: switch (status) {
          400 => 'No se pudo consultar ese juego y año.',
          401 => 'Tu sesión no es válida. Vuelve a iniciar sesión.',
          403 => 'Tu cuenta no tiene acceso al ranking competitivo.',
          _ =>
            'No pudimos cargar el ranking competitivo. Inténtalo nuevamente.',
        },
      );
    } on FormatException {
      throw const ApiError(
        code: 'invalid_competitive_response',
        message:
            'No pudimos cargar el ranking competitivo. Inténtalo nuevamente.',
      );
    }
  }
}
