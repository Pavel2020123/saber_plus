import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';

void main() {
  test('interpreta un diagnóstico completado con resultados por área', () {
    final diagnostic = DiagnosticSummary.fromJson({
      'estado': 'COMPLETADO',
      'diagnosticoId': 'diagnostic-1',
      'totalPreguntas': 15,
      'respuestasCorrectas': 8,
      'porcentaje': 53.3,
      'nivel': 'EN_PROCESO',
      'areaPrioritaria': 'MATEMATICAS',
      'areaFortaleza': 'INGLES',
      'resultadosPorArea': [
        {
          'area': 'MATEMATICAS',
          'totalPreguntas': 3,
          'respuestasCorrectas': 1,
          'porcentaje': 33.3,
          'nivel': 'POR_REFORZAR',
        },
      ],
    });

    expect(diagnostic.status, DiagnosticStatus.completed);
    expect(diagnostic.priorityArea, AcademicArea.mathematics);
    expect(diagnostic.level, DiagnosticLevel.inProgress);
    expect(
      diagnostic.resultsByArea.single.level,
      DiagnosticLevel.needsReinforcement,
    );
  });

  test('selecciona la primera actividad académica pendiente del plan', () {
    final plan = StudyPlanSummary.fromJson({
      'estado': 'LISTO',
      'resumen': {
        'sesionesObjetivo': 5,
        'sesionesCompletadas': 1,
        'minutosObjetivoSemanal': 200,
        'porcentaje': 20,
      },
      'dias': [
        {
          'id': 'rest-1',
          'fecha': '2026-08-27',
          'tipo': 'DESCANSO',
          'titulo': 'Descanso',
          'detalle': 'Pausa',
          'minutos': 0,
          'completada': false,
          'area': null,
        },
        {
          'id': 'study-1',
          'fecha': '2026-08-28',
          'tipo': 'ESTUDIO',
          'titulo': 'Razones y proporciones',
          'detalle': 'Área prioritaria',
          'minutos': 40,
          'completada': false,
          'area': 'MATEMATICAS',
        },
      ],
    });

    expect(plan.status, StudyPlanStatus.ready);
    expect(plan.nextActivity?.id, 'study-1');
    expect(plan.nextActivity?.area, AcademicArea.mathematics);
  });

  test('calcula los días restantes sin incluir horas parciales', () {
    final exam = ActiveExam.fromJson({
      'id': 'calendar-1',
      'anio': 2026,
      'calendario': 'A',
      'fechaExamen': '2026-09-06T00:00:00.000Z',
    });

    expect(exam.daysRemaining(DateTime(2026, 8, 27, 23)), 10);
  });
}
