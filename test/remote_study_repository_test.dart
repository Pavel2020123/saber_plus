import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/study/data/remote_study_repository.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  test('consulta el catálogo usando el valor de área del backend', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'area': 'MATEMATICAS',
                'temas': [
                  {
                    'id': 'theme-1',
                    'nombre': 'Álgebra',
                    'subtemas': <Object>[],
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final catalog = await RemoteStudyRepository(
      dio,
    ).loadCatalog(AcademicArea.mathematics);

    expect(captured.path, '/simulacros/temas');
    expect(captured.queryParameters['area'], 'MATEMATICAS');
    expect(catalog.themes.single.name, 'Álgebra');
  });

  test('guarda el progreso con el DTO aceptado por la API', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {'mensaje': 'Progreso actualizado'},
            ),
          );
        },
      ),
    );

    await RemoteStudyRepository(dio).updateSubtopicProgress('subtopic-1', 100);

    expect(captured.path, '/simulacros/progreso');
    expect(captured.data, {'subtemaId': 'subtopic-1', 'porcentaje': 100});
  });

  test('descarga el PDF autenticado en el directorio de la app', () async {
    final temp = await Directory.systemTemp.createTemp('saberplus-study-test-');
    addTearDown(() => temp.delete(recursive: true));
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 200,
              data: const [37, 80, 68, 70],
            ),
          );
        },
      ),
    );
    final repository = RemoteStudyRepository(
      dio,
      downloadDirectory: () async => temp,
    );

    final pdf = await repository.downloadThemePdf(
      const StudyTheme(id: 'theme-1', name: 'Álgebra', subtopics: []),
    );

    expect(pdf.fileName, 'tema-algebra.pdf');
    expect(await File(pdf.path).readAsBytes(), const [37, 80, 68, 70]);
  });
}
