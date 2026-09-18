import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';

const institutionApprovalLabels = {
  'PENDIENTE': 'Pendiente de revisión',
  'REQUIERE_INFORMACION': 'Necesitamos más información',
  'APROBADA': 'Institución aprobada',
  'RECHAZADA': 'Solicitud rechazada',
  'SUSPENDIDA': 'Institución suspendida',
  'LEGADO_EN_REVISION': 'Revisión de institución existente',
};

class InstitutionApplication {
  InstitutionApplication.fromJson(Map<String, dynamic> json)
    : data = Map.unmodifiable(json) {
    if (!institutionApprovalLabels.containsKey(json['estado']) ||
        json['revision'] is! int ||
        (json['revision'] as int) < 1 ||
        json['id'] is! String ||
        json['mensaje'] is! String ||
        [
          'nombre',
          'ciudad',
          'correoInstitucional',
          'contacto',
          'evidencia',
        ].any((key) => json[key] is! String)) {
      throw const FormatException('Solicitud institucional inválida');
    }
  }
  final Map<String, dynamic> data;
  String get state => data['estado'] as String;
  int get revision => data['revision'] as int;
  String get message => data['mensaje'] as String;
  String field(String key) => data[key] as String? ?? '';
}

class InstitutionApplicationContext {
  const InstitutionApplicationContext({
    this.request,
    required this.canEdit,
    this.transitionUntil,
  });
  final InstitutionApplication? request;
  final bool canEdit;
  final DateTime? transitionUntil;
  factory InstitutionApplicationContext.fromJson(Map<String, dynamic> json) {
    if (json['puedeEditar'] is! bool ||
        (json['solicitud'] != null && json['solicitud'] is! Map)) {
      throw const FormatException('Estado institucional inválido');
    }
    return InstitutionApplicationContext(
      request: json['solicitud'] == null
          ? null
          : InstitutionApplication.fromJson(
              Map<String, dynamic>.from(json['solicitud'] as Map),
            ),
      canEdit: json['puedeEditar'] as bool,
      transitionUntil: json['transicionHasta'] == null
          ? null
          : DateTime.parse(json['transicionHasta'] as String),
    );
  }
}

abstract interface class InstitutionApprovalRepository {
  Future<InstitutionApplicationContext> load({CancelToken? cancelToken});
  Future<List<String>> matches(String name, {CancelToken? cancelToken});
  Future<void> submit(Map<String, dynamic> data, {CancelToken? cancelToken});
}

class RemoteInstitutionApprovalRepository
    implements InstitutionApprovalRepository {
  RemoteInstitutionApprovalRepository(this.dio);
  final Dio dio;
  @override
  Future<InstitutionApplicationContext> load({CancelToken? cancelToken}) async {
    try {
      final result = await dio.get<Map<String, dynamic>>(
        '/instituciones/registro/me',
        cancelToken: cancelToken,
      );
      return InstitutionApplicationContext.fromJson(result.data!);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  @override
  Future<List<String>> matches(String name, {CancelToken? cancelToken}) async {
    try {
      final result = await dio.get<Map<String, dynamic>>(
        '/instituciones/registro/coincidencias',
        queryParameters: {'nombre': name},
        cancelToken: cancelToken,
      );
      final rows = result.data?['coincidencias'];
      if (rows is! List || rows.length > 10) {
        throw const FormatException('Coincidencias inválidas');
      }
      return rows.map((row) {
        if (row is! Map ||
            row['nombre'] is! String ||
            row['ciudad'] is! String) {
          throw const FormatException('Coincidencia inválida');
        }
        return '${row['nombre']} — ${row['ciudad']}';
      }).toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  @override
  Future<void> submit(
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    try {
      await dio.post<Object?>(
        '/instituciones/registro',
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response == null) {
        throw const ApiError(
          code: 'institution_uncertain',
          message:
              'No pudimos confirmar el envío. Actualiza el estado antes de intentarlo otra vez; la solicitud podría haberse guardado.',
        );
      }
      throw ApiError.fromDioException(e);
    }
  }
}

class DemoInstitutionApprovalRepository
    implements InstitutionApprovalRepository {
  InstitutionApplication? _request;
  @override
  Future<InstitutionApplicationContext> load({
    CancelToken? cancelToken,
  }) async => InstitutionApplicationContext(
    request: _request,
    canEdit: _request == null,
  );
  @override
  Future<List<String>> matches(String name, {CancelToken? cancelToken}) async =>
      name.toLowerCase().contains('central')
      ? ['Colegio Central — Bogotá (demostración)']
      : [];
  @override
  Future<void> submit(
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    if (_request != null) {
      throw const ApiError(
        code: '409',
        message: 'Ya tienes una solicitud pendiente.',
      );
    }
    _request = InstitutionApplication.fromJson({
      ...data,
      'id': 'demo-application',
      'estado': 'PENDIENTE',
      'revision': 1,
      'mensaje':
          'Solicitud de demostración recibida. En una cuenta real la revisará ADMIN de SaberPlus.',
    });
  }
}
