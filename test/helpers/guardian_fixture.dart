import 'dart:async';
import 'package:dio/dio.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_resume_store.dart';

const guardianRequestKey = '12345678-1234-4123-8123-123456789abc';
Map<String, dynamic> guardianQuestion(int index) => {
  'id': 'q$index',
  'enunciado': '¿Cuánto es $index + 1?',
  'respuestas': [
    {'id': 'a$index', 'texto': '${index + 1}'},
    {'id': 'b$index', 'texto': '${index + 3}'},
  ],
  'subtema': {
    'id': 's1',
    'nombre': 'Suma',
    'tema': {'nombre': 'Aritmética', 'area': 'MATEMATICAS'},
  },
};
Map<String, dynamic> guardianState({
  int count = 0,
  String status = 'ACTIVO',
  bool competitive = false,
  bool legacy = false,
  String id = 'attempt',
}) => {
  'id': id,
  'area': 'MATEMATICAS',
  'dificultad': 'MEDIO',
  if (!legacy) 'competitive': competitive,
  'estado': status,
  'venceEn': '2026-10-10T12:00:00Z',
  'reglas': {'version': 1, 'questions': 8, 'target': 6, 'shields': 3},
  'revision': [
    for (var i = 1; i <= count; i++)
      {
        'pregunta': guardianQuestion(i),
        'respuestaId': 'a$i',
        'esCorrecta': true,
        'respuestaCorrectaId': 'a$i',
        'explicacion': 'Al sumar uno avanzamos una unidad.',
      },
  ],
  'pregunta': status == 'ACTIVO' ? guardianQuestion(count + 1) : null,
};

class GuardianHarness {
  final values = <String, String>{};
  final requests = <RequestOptions>[];
  bool failWrites = false;
  FutureOr<Object?> Function(RequestOptions)? handler;
  late final store = GuardianResumeStore(
    readValue: (key) async => values[key],
    writeValue: (key, value) async {
      if (failWrites) throw StateError('Owned fixture storage unavailable.');
      values[key] = value;
    },
  );
  late final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:43187'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, interceptor) async {
          requests.add(options);
          try {
            interceptor.resolve(
              Response(
                requestOptions: options,
                data: await handler?.call(options),
                statusCode: 200,
              ),
            );
          } on DioException catch (error) {
            interceptor.reject(error);
          }
        },
      ),
    );
  RemoteGuardianRepository repo({String scope = 'api\u0000student'}) =>
      RemoteGuardianRepository(dio, store, scope: scope);
}
