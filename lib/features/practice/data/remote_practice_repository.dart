import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/practice_history_models.dart';
import '../domain/practice_models.dart';
import '../domain/practice_repository.dart';

class RemotePracticeRepository implements PracticeRepository {
  RemotePracticeRepository(this._dio);

  final Dio _dio;

  @override
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/preguntas/${Uri.encodeComponent(subtopicId)}',
      );
      final session = PracticeSession.fromJson(
        _body(response.data),
        area: area,
        subtopicId: subtopicId,
      );
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_practice',
          message: 'Este subtema todavía no tiene preguntas disponibles.',
        );
      }
      if (session.questions.any((question) => question.area != area)) {
        throw const ApiError(
          code: 'practice_area_mismatch',
          message: 'Las preguntas recibidas no corresponden al área elegida.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeResult> gradePractice({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulacros/calificar',
        data: {
          'intentoId': attemptId,
          'area': area.backendValue,
          'origen': 'PRACTICA',
          'respuestas': answers.map((answer) => answer.toJson()).toList(),
        },
      );
      return PracticeResult.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeSession> startRandomPractice(
    RandomPracticeConfig config,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/generar-personalizado',
        queryParameters: {
          'areas': config.areas.map((area) => area.backendValue).join(','),
          'cantidad': config.questionCount,
          if (config.difficulty case final difficulty?)
            'dificultad': difficulty.backendValue,
        },
      );
      final session = PracticeSession.fromRandomJson(
        _body(response.data),
        areas: config.areas,
      );
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_random_practice',
          message: 'No hay preguntas para esta combinación de áreas.',
        );
      }
      final allowed = config.areas.toSet();
      if (session.questions.any(
        (question) => !allowed.contains(question.area),
      )) {
        throw const ApiError(
          code: 'random_practice_area_mismatch',
          message: 'La sesión contiene un área que no fue seleccionada.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeResult> gradeRandomPractice({
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulacros/calificar-personalizado',
        data: {
          'intentoId': attemptId,
          'respuestas': answers.map((answer) => answer.toJson()).toList(),
        },
      );
      return PracticeResult.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeSession> startAreaSimulation(AcademicArea area) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/generar',
        queryParameters: {'area': area.backendValue},
      );
      final session = PracticeSession.fromSimulationJson(
        _body(response.data),
        area: area,
      );
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_simulation',
          message: 'Esta área todavía no tiene preguntas para el simulacro.',
        );
      }
      if (session.questions.any((question) => question.area != area)) {
        throw const ApiError(
          code: 'simulation_area_mismatch',
          message: 'El simulacro contiene preguntas de otra área.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeResult> gradeAreaSimulation({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulacros/calificar',
        data: {
          'intentoId': attemptId,
          'area': area.backendValue,
          'origen': 'SIMULACRO',
          'respuestas': answers.map((answer) => answer.toJson()).toList(),
        },
      );
      return PracticeResult.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<SimulationHistory> loadSimulationHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/historial',
      );
      return SimulationHistory.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<AnswerHistory> loadAnswerHistory(AnswerHistoryFilter filter) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/historial-respuestas',
        queryParameters: {
          if (filter.area case final area?) 'area': area.backendValue,
          if (filter.outcome == AnswerOutcomeFilter.correct)
            'resultado': 'correctas',
          if (filter.outcome == AnswerOutcomeFilter.incorrect)
            'resultado': 'incorrectas',
          'limite': filter.limit.clamp(1, 100),
        },
      );
      return AnswerHistory.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}
