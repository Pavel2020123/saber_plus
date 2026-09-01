import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/battle_models.dart';
import '../domain/battle_repository.dart';

class RemoteBattleRepository implements BattleRepository {
  RemoteBattleRepository(this._dio);

  final Dio _dio;

  @override
  Future<BattleDashboard> loadDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/batallas');
      return BattleDashboard.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<BattleDetail> create({
    required BattleMode mode,
    AcademicArea? area,
    bool privateInvitation = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/batallas',
        data: {
          'modo': mode.backendValue,
          if (area != null) 'area': area.backendValue,
          'invitacionPrivada': privateInvitation,
        },
      );
      return BattleDetail.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<BattleDetail> joinInvitation(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/batallas/invitaciones/unirse',
        data: {'codigo': code.trim().toUpperCase()},
      );
      return BattleDetail.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<BattleDetail> loadDetail(String battleId) =>
      _detailRequest('GET', '/batallas/${Uri.encodeComponent(battleId)}');

  @override
  Future<BattleDetail> start(String battleId) => _detailRequest(
    'POST',
    '/batallas/${Uri.encodeComponent(battleId)}/iniciar',
  );

  @override
  Future<BattleDetail> answer({
    required String battleId,
    required String questionId,
    required String answerId,
  }) => _detailRequest(
    'POST',
    '/batallas/${Uri.encodeComponent(battleId)}/respuestas',
    data: {'preguntaId': questionId, 'respuestaId': answerId},
  );

  @override
  Future<BattleDetail> finish(String battleId) => _detailRequest(
    'POST',
    '/batallas/${Uri.encodeComponent(battleId)}/finalizar',
  );

  @override
  Future<BattleDetail> cancel(String battleId) => _detailRequest(
    'POST',
    '/batallas/${Uri.encodeComponent(battleId)}/cancelar',
  );

  @override
  Future<void> blockRival(String battleId) async {
    try {
      await _dio.post<void>(
        '/batallas/${Uri.encodeComponent(battleId)}/bloquear-rival',
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> report({
    required String battleId,
    required BattleReportReason reason,
    String? details,
  }) async {
    try {
      await _dio.post<void>(
        '/batallas/${Uri.encodeComponent(battleId)}/reportes',
        data: {
          'motivo': reason.backendValue,
          if (details?.trim().isNotEmpty == true) 'detalle': details!.trim(),
        },
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<List<BlockedRival>> loadBlocks() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/batallas/bloqueos',
      );
      final body = _body(response.data);
      BattlePrivacy.fromJson(_map(body['privacidad']));
      return _list(body['bloqueos'])
          .map((item) => BlockedRival.fromJson(_map(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> unblock(String blockId) async {
    try {
      await _dio.delete<void>(
        '/batallas/bloqueos/${Uri.encodeComponent(blockId)}',
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<BattleDetail> _detailRequest(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(method: method),
      );
      return BattleDetail.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) return const {};
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : value;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Object?> _list(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];
