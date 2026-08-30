import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/historical_simulations/domain/historical_simulation_models.dart';

void main() {
  test('ordena años y habilita solo contenido con derechos verificables', () {
    final catalog = HistoricalSimulationCatalog.fromJson({
      'actualizadoEn': '2026-08-30T12:00:00.000Z',
      'ediciones': [
        {
          'id': 'edition-2024',
          'anio': 2024,
          'titulo': 'Edición propia 2024',
          'descripcion': 'Prueba archivada.',
          'proveedor': 'SaberPlus',
          'totalPreguntas': 150,
          'estado': 'DISPONIBLE',
          'derechos': {
            'tipo': 'PROPIO',
            'titular': 'SaberPlus',
            'referencia': 'SP-OWN-2024',
          },
        },
        {
          'id': 'edition-2025',
          'anio': 2025,
          'titulo': 'Edición pendiente 2025',
          'descripcion': 'Pendiente.',
          'proveedor': 'Por definir',
          'totalPreguntas': 0,
          'estado': 'PROXIMAMENTE',
        },
      ],
    });

    expect(catalog.years, [2025, 2024]);
    expect(catalog.editions.first.year, 2025);
    expect(catalog.editions.last.canStart, isTrue);
    expect(catalog.editions.first.canStart, isFalse);
    expect(catalog.updatedAt?.isUtc, isFalse);
  });

  test('rechaza una edición disponible sin autorización', () {
    expect(
      () => HistoricalSimulationEdition.fromJson({
        'id': 'unsafe-2024',
        'anio': 2024,
        'titulo': 'Edición sin licencia',
        'descripcion': 'No válida.',
        'proveedor': 'Desconocido',
        'totalPreguntas': 150,
        'estado': 'DISPONIBLE',
      }),
      throwsFormatException,
    );
  });
}
