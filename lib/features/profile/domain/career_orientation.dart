import '../../academic/domain/academic_models.dart';

enum CareerAffinity {
  high('Mayor afinidad académica'),
  related('Afinidad relacionada'),
  exploratory('Para explorar');

  const CareerAffinity(this.label);

  final String label;
}

class CareerPath {
  const CareerPath({
    required this.id,
    required this.title,
    required this.description,
    required this.relatedAreas,
    required this.examples,
  });

  final String id;
  final String title;
  final String description;
  final List<AcademicArea> relatedAreas;
  final List<String> examples;
}

class CareerRecommendation {
  const CareerRecommendation({
    required this.path,
    required this.affinity,
    required this.academicIndex,
    required this.evidenceAreas,
  });

  final CareerPath path;
  final CareerAffinity affinity;
  final double academicIndex;
  final int evidenceAreas;
}

class CareerOrientation {
  const CareerOrientation({required this.recommendations});

  final List<CareerRecommendation> recommendations;

  factory CareerOrientation.fromAreaScores(
    Map<AcademicArea, double> areaScores,
  ) {
    final ranked = <({CareerPath path, double score, int evidence})>[];
    for (final path in careerPathCatalog) {
      final values = path.relatedAreas
          .where(areaScores.containsKey)
          .map((area) => areaScores[area]!.clamp(0, 100))
          .toList(growable: false);
      if (values.isEmpty) continue;
      ranked.add((
        path: path,
        score: values.reduce((left, right) => left + right) / values.length,
        evidence: values.length,
      ));
    }
    ranked.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      if (byScore != 0) return byScore;
      return left.path.id.compareTo(right.path.id);
    });

    return CareerOrientation(
      recommendations: List.generate(ranked.length, (index) {
        final item = ranked[index];
        final affinity = item.evidence < 2
            ? CareerAffinity.exploratory
            : index < 2
            ? CareerAffinity.high
            : index < 4
            ? CareerAffinity.related
            : CareerAffinity.exploratory;
        return CareerRecommendation(
          path: item.path,
          affinity: affinity,
          academicIndex: item.score,
          evidenceAreas: item.evidence,
        );
      }, growable: false),
    );
  }

  static const empty = CareerOrientation(recommendations: []);
}

const careerPathCatalog = <CareerPath>[
  CareerPath(
    id: 'engineering-data',
    title: 'Ingeniería, tecnología y datos',
    description:
        'Rutas centradas en resolver problemas, diseñar sistemas y analizar información.',
    relatedAreas: [AcademicArea.mathematics, AcademicArea.naturalSciences],
    examples: [
      'Ingenierías',
      'Ciencia de datos',
      'Desarrollo de software',
      'Estadística',
    ],
  ),
  CareerPath(
    id: 'health-life',
    title: 'Salud y ciencias de la vida',
    description:
        'Opciones relacionadas con el cuidado, la investigación y los sistemas vivos.',
    relatedAreas: [AcademicArea.naturalSciences, AcademicArea.criticalReading],
    examples: ['Medicina', 'Enfermería', 'Biología', 'Salud pública'],
  ),
  CareerPath(
    id: 'law-society',
    title: 'Derecho, sociedad y comunicación',
    description:
        'Rutas para comprender contextos, argumentar y trabajar con comunidades.',
    relatedAreas: [AcademicArea.socialSciences, AcademicArea.criticalReading],
    examples: ['Derecho', 'Comunicación', 'Sociología', 'Ciencia política'],
  ),
  CareerPath(
    id: 'business-economy',
    title: 'Economía, negocios y administración',
    description:
        'Opciones para analizar recursos, organizaciones, mercados y decisiones.',
    relatedAreas: [
      AcademicArea.mathematics,
      AcademicArea.socialSciences,
      AcademicArea.english,
    ],
    examples: [
      'Economía',
      'Administración',
      'Finanzas',
      'Negocios internacionales',
    ],
  ),
  CareerPath(
    id: 'languages-global',
    title: 'Idiomas y entornos internacionales',
    description:
        'Rutas conectadas con lenguas, culturas y comunicación entre contextos.',
    relatedAreas: [
      AcademicArea.english,
      AcademicArea.criticalReading,
      AcademicArea.socialSciences,
    ],
    examples: ['Lenguas modernas', 'Traducción', 'Relaciones internacionales'],
  ),
  CareerPath(
    id: 'education-humanities',
    title: 'Educación, artes y humanidades',
    description:
        'Opciones para enseñar, crear, interpretar y conservar conocimiento y cultura.',
    relatedAreas: [AcademicArea.criticalReading, AcademicArea.socialSciences],
    examples: ['Licenciaturas', 'Historia', 'Filosofía', 'Literatura'],
  ),
];
