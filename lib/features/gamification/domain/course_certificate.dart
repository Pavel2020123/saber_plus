enum CourseCertificateType {
  reading('LECTURA_CRITICA', 'Lectura crítica'),
  mathematics('MATEMATICAS', 'Matemáticas'),
  science('CIENCIAS_NATURALES', 'Ciencias naturales'),
  social('SOCIALES_CIUDADANAS', 'Sociales y ciudadanas'),
  english('INGLES', 'Inglés'),
  course('CURSO_COMPLETO', 'Curso completo de SaberPlus');

  const CourseCertificateType(this.id, this.title);
  final String id;
  final String title;
}

class CourseCertificate {
  const CourseCertificate({
    required this.type,
    this.completed = 0,
    this.total = 0,
    this.available = false,
  });

  final CourseCertificateType type;
  final int completed;
  final int total;
  final bool available;
  String get id => type.id;
  String get title => type.title;
  String get unit =>
      type == CourseCertificateType.course ? 'áreas' : 'lecciones';

  static List<CourseCertificate> parseList(Object? data) {
    if (data is! List) {
      throw const FormatException('Catálogo de certificados no válido.');
    }
    return CourseCertificateType.values
        .map((type) {
          final matches = data
              .whereType<Map>()
              .where((item) => item['id'] == type.id)
              .toList();
          if (matches.length != 1) {
            throw const FormatException('Catálogo de certificados incompleto.');
          }
          final item = matches.single;
          final total = item['total'];
          final completed = item['completadas'];
          if (total is! int ||
              completed is! int ||
              total < 0 ||
              completed < 0 ||
              completed > total ||
              (type == CourseCertificateType.course && total != 5)) {
            throw const FormatException('Progreso de certificados no válido.');
          }
          return CourseCertificate(
            type: type,
            completed: completed,
            total: total,
            available:
                item['disponible'] == true && total > 0 && completed == total,
          );
        })
        .toList(growable: false);
  }
}
