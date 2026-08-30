import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/profile/domain/career_orientation.dart';

void main() {
  test('ordena las rutas según la afinidad de las áreas relacionadas', () {
    final orientation = CareerOrientation.fromAreaScores({
      AcademicArea.mathematics: 95,
      AcademicArea.naturalSciences: 90,
      AcademicArea.criticalReading: 70,
      AcademicArea.socialSciences: 60,
      AcademicArea.english: 50,
    });

    expect(orientation.recommendations, hasLength(careerPathCatalog.length));
    expect(orientation.recommendations.first.path.id, 'engineering-data');
    expect(orientation.recommendations.first.affinity, CareerAffinity.high);
    expect(orientation.recommendations.first.academicIndex, 92.5);
  });

  test('no afirma afinidad alta con evidencia de una sola materia', () {
    final orientation = CareerOrientation.fromAreaScores({
      AcademicArea.english: 90,
    });

    expect(orientation.recommendations, isNotEmpty);
    expect(
      orientation.recommendations.every(
        (item) => item.affinity == CareerAffinity.exploratory,
      ),
      isTrue,
    );
  });

  test('mantiene la orientación vacía cuando no hay resultados', () {
    final orientation = CareerOrientation.fromAreaScores(const {});

    expect(orientation.recommendations, isEmpty);
  });
}
