import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/vocational_orientation.dart';
import '../domain/vocational_orientation_repository.dart';

class RemoteVocationalOrientationRepository
    implements VocationalOrientationRepository {
  const RemoteVocationalOrientationRepository(this._dio);

  final Dio _dio;
  static const _base = '/orientacion-vocacional';

  Future<T> _request<T>(
    Future<Response<Object?>> Function() run,
    T Function(Object?) parse,
  ) async {
    try {
      return parse((await run()).data);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } on FormatException {
      throw const ApiError(
        code: 'invalid_vocational_response',
        message:
            'El servidor devolvió datos de orientación incompatibles. Intenta nuevamente.',
      );
    }
  }

  @override
  Future<VocationalQuestionnaire> questionnaire() => _request(
    () => _dio.get<Object?>('$_base/cuestionario'),
    VocationalQuestionnaire.parse,
  );

  @override
  Future<VocationalAttempt?> current() =>
      _request(() => _dio.get<Object?>(_base), parseCurrentVocationalAttempt);

  @override
  Future<VocationalAttempt> start() => _request(
    () => _dio.post<Object?>('$_base/intentos', data: <String, Object?>{}),
    VocationalAttempt.parse,
  );

  @override
  Future<VocationalAttempt> saveAnswer(
    String attemptId,
    String questionId,
    VocationalAnswer answer,
  ) => _request(
    () => _dio.patch<Object?>(
      '$_base/intentos/$attemptId/respuestas',
      data: {
        'respuestas': [
          {'preguntaId': questionId, 'valor': answer.wireValue},
        ],
      },
    ),
    VocationalAttempt.parse,
  );

  @override
  Future<VocationalAttempt> finish(String attemptId) => _request(
    () => _dio.post<Object?>(
      '$_base/intentos/$attemptId/finalizar',
      data: <String, Object?>{},
    ),
    VocationalAttempt.parse,
  );

  @override
  Future<VocationalHistory> history(int page) => _request(
    () => _dio.get<Object?>(
      '$_base/historial',
      queryParameters: {'pagina': page},
    ),
    VocationalHistory.parse,
  );

  @override
  Future<VocationalAttempt> getAttempt(String attemptId) => _request(
    () => _dio.get<Object?>('$_base/intentos/$attemptId'),
    VocationalAttempt.parse,
  );

  @override
  Future<void> deleteAttempt(String attemptId) async {
    try {
      await _dio.delete<void>('$_base/intentos/$attemptId');
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
