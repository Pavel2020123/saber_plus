import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  test('interpreta el árbol académico y sus recursos', () {
    final catalog = StudyCatalog.fromJson({
      'area': 'MATEMATICAS',
      'temas': [
        {
          'id': 'theme-1',
          'nombre': 'Razones y proporciones',
          'subtemas': [
            {
              'id': 'subtopic-1',
              'nombre': 'Regla de tres',
              'totalPreguntas': 5,
              'contenido': '# Regla de tres',
              'videoUrl': 'https://example.com/video',
              'imagenUrl': 'regla.jpg',
              'tipoInteractivo': 'CLOZE',
              'datosInteractivo': {
                'textoConEspacios': 'Completa ___',
                'espacios': [
                  {
                    'opciones': ['10', '20'],
                    'correctaIndex': 1,
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    expect(catalog.area, AcademicArea.mathematics);
    expect(catalog.totalSubtopics, 1);
    final subtopic = catalog.themes.single.subtopics.single;
    expect(subtopic.name, 'Regla de tres');
    expect(subtopic.hasLearningResource, isTrue);
    expect(subtopic.clozeActivity?.blanks.single.correctIndex, 1);
  });

  test('interpreta el progreso por subtema', () {
    final progress = StudyProgress.fromJson({
      'totalSubtemas': 20,
      'temasVistos': 3,
      'temasCompletados': 2,
      'porcentajeGeneral': 10,
      'porSubtema': {'subtopic-1': 100, 'subtopic-2': 45},
    });

    expect(progress.completedSubtopics, 2);
    expect(progress.percentageFor('subtopic-1'), 100);
    expect(progress.percentageFor('unknown'), 0);
  });

  test('convierte áreas entre API y rutas móviles', () {
    expect(AcademicArea.mathematics.backendValue, 'MATEMATICAS');
    expect(AcademicArea.fromSlug('matematicas'), AcademicArea.mathematics);
  });
}
