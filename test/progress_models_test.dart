import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

void main() {
  test('interpreta el resumen y detalle completo del cuaderno', () {
    final notebook = ErrorNotebook.fromJson({
      'resumen': {'total': 1, 'pendientes': 0, 'repasando': 1, 'dominados': 0},
      'errores': [
        {
          'preguntaId': 'question-1',
          'enunciado': '¿Cuál es el valor de x?',
          'explicacion': 'Se aplica una proporción directa.',
          'dificultad': 'MEDIO',
          'area': 'MATEMATICAS',
          'vecesFallada': 2,
          'ultimoErrorEn': '2026-08-28T15:00:00.000Z',
          'respuestaSeleccionada': {'id': 'answer-1', 'texto': '4'},
          'respuestaCorrecta': {
            'id': 'answer-2',
            'texto': '6',
            'explicacion': 'Multiplica en cruz.',
          },
          'tema': 'Razones y proporciones',
          'subtema': 'Regla de tres',
          'caso': {'id': 'case-1', 'titulo': 'Venta de cuadernos'},
          'nota': 'Revisar el orden de los datos.',
          'estado': 'REPASANDO',
        },
      ],
    });

    expect(notebook.summary.reviewing, 1);
    expect(notebook.errors.single.area, AcademicArea.mathematics);
    expect(notebook.errors.single.status, NotebookStatus.reviewing);
    expect(notebook.errors.single.timesFailed, 2);
    expect(notebook.errors.single.correctAnswer?.text, '6');
    expect(notebook.errors.single.caseTitle, 'Venta de cuadernos');
  });

  test('mapea los estados del cuaderno al contrato del backend', () {
    expect(NotebookStatus.pending.backendValue, 'PENDIENTE');
    expect(NotebookStatus.reviewing.backendValue, 'REPASANDO');
    expect(NotebookStatus.mastered.backendValue, 'DOMINADO');
    expect(NotebookStatus.fromBackend('DOMINADO'), NotebookStatus.mastered);
  });
}
