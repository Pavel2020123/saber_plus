import '../../practice/domain/practice_models.dart';

enum HistoricalSimulationAvailability {
  available('DISPONIBLE', 'Disponible'),
  comingSoon('PROXIMAMENTE', 'Próximamente'),
  restricted('RESTRINGIDO', 'Sin autorización');

  const HistoricalSimulationAvailability(this.backendValue, this.label);

  final String backendValue;
  final String label;

  factory HistoricalSimulationAvailability.fromBackend(String value) =>
      values.firstWhere(
        (item) => item.backendValue == value.toUpperCase(),
        orElse: () => throw FormatException(
          'Estado de simulacro histórico no reconocido: $value',
        ),
      );
}

enum HistoricalContentRightsType {
  owned('PROPIO', 'Contenido propio'),
  licensed('LICENCIA', 'Contenido licenciado'),
  reusable('REUTILIZABLE', 'Reutilización autorizada');

  const HistoricalContentRightsType(this.backendValue, this.label);

  final String backendValue;
  final String label;

  factory HistoricalContentRightsType.fromBackend(String value) =>
      values.firstWhere(
        (item) => item.backendValue == value.toUpperCase(),
        orElse: () => throw FormatException(
          'Tipo de derechos históricos no reconocido: $value',
        ),
      );
}

class HistoricalContentRights {
  const HistoricalContentRights({
    required this.type,
    required this.holder,
    required this.reference,
  });

  final HistoricalContentRightsType type;
  final String holder;
  final String reference;

  bool get isVerifiable =>
      holder.trim().isNotEmpty && reference.trim().isNotEmpty;

  factory HistoricalContentRights.fromJson(Map<String, dynamic> json) =>
      HistoricalContentRights(
        type: HistoricalContentRightsType.fromBackend(
          json['tipo'] as String? ?? '',
        ),
        holder: (json['titular'] as String? ?? '').trim(),
        reference: (json['referencia'] as String? ?? '').trim(),
      );
}

class HistoricalSimulationEdition {
  const HistoricalSimulationEdition({
    required this.id,
    required this.year,
    required this.title,
    required this.description,
    required this.provider,
    required this.questionCount,
    required this.availability,
    this.rights,
  });

  final String id;
  final int year;
  final String title;
  final String description;
  final String provider;
  final int questionCount;
  final HistoricalSimulationAvailability availability;
  final HistoricalContentRights? rights;

  bool get canStart =>
      availability == HistoricalSimulationAvailability.available &&
      questionCount == OfficialSimulationBlock.totalQuestionCount &&
      (rights?.isVerifiable ?? false);

  factory HistoricalSimulationEdition.fromJson(Map<String, dynamic> json) {
    final rawRights = json['derechos'];
    final edition = HistoricalSimulationEdition(
      id: (json['id'] as String? ?? '').trim(),
      year: (json['anio'] as num? ?? 0).toInt(),
      title: (json['titulo'] as String? ?? '').trim(),
      description: (json['descripcion'] as String? ?? '').trim(),
      provider: (json['proveedor'] as String? ?? '').trim(),
      questionCount: (json['totalPreguntas'] as num? ?? 0).toInt(),
      availability: HistoricalSimulationAvailability.fromBackend(
        json['estado'] as String? ?? '',
      ),
      rights: rawRights is Map
          ? HistoricalContentRights.fromJson(
              Map<String, dynamic>.from(rawRights),
            )
          : null,
    );
    if (edition.id.isEmpty ||
        edition.title.isEmpty ||
        edition.year < 2000 ||
        edition.year > 2100) {
      throw const FormatException('Metadatos históricos incompletos.');
    }
    if (edition.availability == HistoricalSimulationAvailability.available &&
        !edition.canStart) {
      throw const FormatException(
        'Una edición disponible requiere 150 preguntas y derechos verificables.',
      );
    }
    return edition;
  }
}

class HistoricalSimulationCatalog {
  HistoricalSimulationCatalog({
    required List<HistoricalSimulationEdition> editions,
    this.updatedAt,
  }) : editions = List.unmodifiable(
         [...editions]..sort((left, right) => right.year.compareTo(left.year)),
       );

  final List<HistoricalSimulationEdition> editions;
  final DateTime? updatedAt;

  List<int> get years =>
      editions.map((edition) => edition.year).toSet().toList()
        ..sort((left, right) => right.compareTo(left));

  factory HistoricalSimulationCatalog.fromJson(Map<String, dynamic> json) =>
      HistoricalSimulationCatalog(
        editions: (json['ediciones'] as List<dynamic>? ?? const [])
            .map(
              (item) => HistoricalSimulationEdition.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
        updatedAt: DateTime.tryParse(
          json['actualizadoEn'] as String? ?? '',
        )?.toLocal(),
      );
}
