import 'institution_group_models.dart';

class BasicAnalyticsMetrics {
  const BasicAnalyticsMetrics({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalSimulations,
    required this.averageScore,
    required this.averageProgress,
    this.lastActivity,
  });

  final int totalStudents;
  final int activeStudents;
  final int totalSimulations;
  final double averageScore;
  final double averageProgress;
  final DateTime? lastActivity;

  factory BasicAnalyticsMetrics.fromJson(Map<String, dynamic> json) =>
      BasicAnalyticsMetrics(
        totalStudents: json['totalEstudiantes'] as int? ?? 0,
        activeStudents: json['estudiantesActivos'] as int? ?? 0,
        totalSimulations: json['totalSimulacros'] as int? ?? 0,
        averageScore: (json['promedioPuntaje'] as num?)?.toDouble() ?? 0,
        averageProgress: (json['progresoPromedio'] as num?)?.toDouble() ?? 0,
        lastActivity: _optionalDate(json['ultimaActividad']),
      );
}

class BasicGroupAnalytics extends BasicAnalyticsMetrics {
  const BasicGroupAnalytics({
    required this.id,
    required this.name,
    required this.grade,
    required super.totalStudents,
    required super.activeStudents,
    required super.totalSimulations,
    required super.averageScore,
    required super.averageProgress,
    super.lastActivity,
  });

  final String id;
  final String name;
  final InstitutionGrade grade;

  factory BasicGroupAnalytics.fromJson(Map<String, dynamic> json) {
    _rejectStudentIdentityFields(json);
    final metrics = BasicAnalyticsMetrics.fromJson(json);
    return BasicGroupAnalytics(
      id: json['id'] as String,
      name: json['nombre'] as String,
      grade: InstitutionGrade.fromBackend(json['grado'] as String?),
      totalStudents: metrics.totalStudents,
      activeStudents: metrics.activeStudents,
      totalSimulations: metrics.totalSimulations,
      averageScore: metrics.averageScore,
      averageProgress: metrics.averageProgress,
      lastActivity: metrics.lastActivity,
    );
  }
}

class BasicAnalyticsPlan {
  const BasicAnalyticsPlan({
    required this.name,
    required this.advertisingEnabled,
    this.groupLimit,
    this.studentLimit,
  });

  final String name;
  final bool advertisingEnabled;
  final int? groupLimit;
  final int? studentLimit;

  factory BasicAnalyticsPlan.fromJson(Map<String, dynamic> json) =>
      BasicAnalyticsPlan(
        name: json['nombre'] as String? ?? 'GRATIS',
        advertisingEnabled: json['publicidadHabilitada'] as bool? ?? true,
        groupLimit: json['limiteGrupos'] as int?,
        studentLimit: json['limiteEstudiantes'] as int?,
      );
}

class TeacherBasicAnalytics {
  const TeacherBasicAnalytics({
    required this.scope,
    required this.periodDays,
    required this.generatedAt,
    required this.plan,
    required this.summary,
    required this.groups,
    required this.privacyDescription,
  });

  final String scope;
  final int periodDays;
  final DateTime generatedAt;
  final BasicAnalyticsPlan plan;
  final BasicAnalyticsMetrics summary;
  final List<BasicGroupAnalytics> groups;
  final String privacyDescription;

  factory TeacherBasicAnalytics.fromJson(Map<String, dynamic> json) {
    _rejectStudentIdentityFields(json);
    final privacy = Map<String, dynamic>.from(
      json['privacidad'] as Map? ?? const {},
    );
    if (privacy['incluyeIdentidades'] != false) {
      throw const FormatException(
        'La analítica básica no puede incluir identidades.',
      );
    }
    return TeacherBasicAnalytics(
      scope: json['alcance'] as String? ?? 'GRUPOS_ASIGNADOS',
      periodDays: json['periodoDias'] as int? ?? 30,
      generatedAt: DateTime.parse(json['generadoEn'] as String).toLocal(),
      plan: BasicAnalyticsPlan.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map? ?? const {}),
      ),
      summary: BasicAnalyticsMetrics.fromJson(
        Map<String, dynamic>.from(json['resumen'] as Map? ?? const {}),
      ),
      groups: (json['grupos'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BasicGroupAnalytics.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      privacyDescription:
          privacy['descripcion'] as String? ??
          'Indicadores agregados sin identidades.',
    );
  }
}

DateTime? _optionalDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

void _rejectStudentIdentityFields(Object? value) {
  const forbidden = {
    'correo',
    'email',
    'usuarioId',
    'estudianteId',
    'estudiantes',
  };
  if (value is Map) {
    for (final entry in value.entries) {
      if (forbidden.contains(entry.key)) {
        throw const FormatException(
          'La respuesta de analítica contiene datos de identidad.',
        );
      }
      _rejectStudentIdentityFields(entry.value);
    }
  } else if (value is List) {
    for (final item in value) {
      _rejectStudentIdentityFields(item);
    }
  }
}
