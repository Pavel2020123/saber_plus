class DetailedAnalyticsSummary {
  const DetailedAnalyticsSummary({
    required this.totalStudents,
    required this.averageScore,
    required this.totalSimulations,
    required this.studentsNeedingSupport,
  });

  final int totalStudents;
  final double averageScore;
  final int totalSimulations;
  final int studentsNeedingSupport;

  factory DetailedAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      DetailedAnalyticsSummary(
        totalStudents: json['totalEstudiantes'] as int? ?? 0,
        averageScore: (json['promedioGeneral'] as num?)?.toDouble() ?? 0,
        totalSimulations: json['totalSimulacros'] as int? ?? 0,
        studentsNeedingSupport: json['estudiantesPorReforzar'] as int? ?? 0,
      );
}

class InstitutionAcademicPriority {
  const InstitutionAcademicPriority({
    required this.area,
    required this.students,
    this.average,
  });

  final String area;
  final int students;
  final double? average;

  String get areaLabel => institutionAreaLabel(area);

  factory InstitutionAcademicPriority.fromJson(Map<String, dynamic> json) =>
      InstitutionAcademicPriority(
        area: json['area'] as String,
        students: json['estudiantes'] as int? ?? 0,
        average: (json['promedio'] as num?)?.toDouble(),
      );
}

class DetailedStudentArea {
  const DetailedStudentArea({
    required this.area,
    required this.average,
    required this.attempts,
  });

  final String area;
  final double average;
  final int attempts;

  String get areaLabel => institutionAreaLabel(area);

  factory DetailedStudentArea.fromJson(Map<String, dynamic> json) =>
      DetailedStudentArea(
        area: json['area'] as String,
        average: (json['promedio'] as num?)?.toDouble() ?? 0,
        attempts: json['cantidad'] as int? ?? 0,
      );
}

class DetailedStudentAnalytics {
  const DetailedStudentAnalytics({
    required this.id,
    required this.name,
    required this.email,
    required this.groups,
    required this.xp,
    required this.totalSimulations,
    required this.averageScore,
    required this.progress,
    required this.areas,
    required this.academicStatus,
    this.priorityArea,
    this.lastActivity,
  });

  final String id;
  final String name;
  final String email;
  final List<String> groups;
  final int xp;
  final int totalSimulations;
  final double averageScore;
  final double progress;
  final List<DetailedStudentArea> areas;
  final String academicStatus;
  final String? priorityArea;
  final DateTime? lastActivity;

  String? get priorityAreaLabel =>
      priorityArea == null ? null : institutionAreaLabel(priorityArea!);

  factory DetailedStudentAnalytics.fromJson(Map<String, dynamic> json) =>
      DetailedStudentAnalytics(
        id: json['id'] as String,
        name: json['nombre'] as String,
        email: json['correo'] as String,
        groups: (json['grupos'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => item['nombre'] as String)
            .toList(growable: false),
        xp: json['xpTotal'] as int? ?? 0,
        totalSimulations: json['totalSimulacros'] as int? ?? 0,
        averageScore: (json['promedioPuntaje'] as num?)?.toDouble() ?? 0,
        progress: (json['progresoPorcentaje'] as num?)?.toDouble() ?? 0,
        areas: _mapList(json['porArea'], DetailedStudentArea.fromJson),
        academicStatus: json['estadoAcademico'] as String? ?? 'SIN_DATOS',
        priorityArea: json['areaPrioritaria'] as String?,
        lastActivity: _optionalDate(json['ultimaActividad']),
      );
}

class TeacherDetailedAnalytics {
  const TeacherDetailedAnalytics({
    required this.scope,
    required this.generatedAt,
    required this.planName,
    required this.groupLimit,
    required this.studentLimit,
    required this.summary,
    required this.priorities,
    required this.students,
    this.expiresAt,
  });

  final String scope;
  final DateTime generatedAt;
  final String planName;
  final int? groupLimit;
  final int? studentLimit;
  final DateTime? expiresAt;
  final DetailedAnalyticsSummary summary;
  final List<InstitutionAcademicPriority> priorities;
  final List<DetailedStudentAnalytics> students;

  factory TeacherDetailedAnalytics.fromJson(Map<String, dynamic> json) {
    final plan = Map<String, dynamic>.from(json['plan'] as Map? ?? const {});
    return TeacherDetailedAnalytics(
      scope: json['alcance'] as String? ?? 'GRUPOS_ASIGNADOS',
      generatedAt: DateTime.parse(json['generadoEn'] as String).toLocal(),
      planName: plan['nombre'] as String? ?? 'SIN_ANUNCIOS',
      groupLimit: plan['limiteGrupos'] as int?,
      studentLimit: plan['limiteEstudiantes'] as int?,
      expiresAt: _optionalDate(plan['venceEn']),
      summary: DetailedAnalyticsSummary.fromJson(
        Map<String, dynamic>.from(json['institucion'] as Map? ?? const {}),
      ),
      priorities: _mapList(
        json['prioridades'],
        InstitutionAcademicPriority.fromJson,
      ),
      students: _mapList(
        json['estudiantes'],
        DetailedStudentAnalytics.fromJson,
      ),
    );
  }
}

class RiskReason {
  const RiskReason({
    required this.code,
    required this.level,
    required this.title,
    required this.detail,
  });

  final String code;
  final String level;
  final String title;
  final String detail;

  factory RiskReason.fromJson(Map<String, dynamic> json) => RiskReason(
    code: json['codigo'] as String? ?? 'RIESGO',
    level: json['nivel'] as String? ?? 'ATENCION',
    title: json['titulo'] as String? ?? 'Revisión recomendada',
    detail: json['detalle'] as String? ?? '',
  );
}

class StudentRiskAlert {
  const StudentRiskAlert({
    required this.studentId,
    required this.name,
    required this.email,
    required this.groups,
    required this.level,
    required this.reasons,
    required this.daysInactive,
    this.priorityArea,
  });

  final String studentId;
  final String name;
  final String email;
  final List<String> groups;
  final String level;
  final List<RiskReason> reasons;
  final int daysInactive;
  final String? priorityArea;

  String? get priorityAreaLabel =>
      priorityArea == null ? null : institutionAreaLabel(priorityArea!);

  factory StudentRiskAlert.fromJson(Map<String, dynamic> json) {
    final student = Map<String, dynamic>.from(
      json['estudiante'] as Map? ?? const {},
    );
    final activity = Map<String, dynamic>.from(
      json['actividad'] as Map? ?? const {},
    );
    return StudentRiskAlert(
      studentId: student['id'] as String,
      name: student['nombre'] as String,
      email: student['correo'] as String,
      groups: (student['grupos'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item['nombre'] as String)
          .toList(growable: false),
      level: json['nivel'] as String? ?? 'ATENCION',
      reasons: _mapList(json['razones'], RiskReason.fromJson),
      daysInactive: activity['diasSinActividad'] as int? ?? 0,
      priorityArea: json['areaPrioritaria'] as String?,
    );
  }
}

class RiskSummary {
  const RiskSummary({
    required this.totalStudents,
    required this.atRisk,
    required this.critical,
    required this.high,
    required this.attention,
  });

  final int totalStudents;
  final int atRisk;
  final int critical;
  final int high;
  final int attention;

  factory RiskSummary.fromJson(Map<String, dynamic> json) => RiskSummary(
    totalStudents: json['totalEstudiantes'] as int? ?? 0,
    atRisk: json['enRiesgo'] as int? ?? 0,
    critical: json['criticas'] as int? ?? 0,
    high: json['altas'] as int? ?? 0,
    attention: json['atencion'] as int? ?? 0,
  );
}

class TeacherRiskReport {
  const TeacherRiskReport({
    required this.scope,
    required this.generatedAt,
    required this.summary,
    required this.alerts,
  });

  final String scope;
  final DateTime generatedAt;
  final RiskSummary summary;
  final List<StudentRiskAlert> alerts;

  factory TeacherRiskReport.fromJson(Map<String, dynamic> json) =>
      TeacherRiskReport(
        scope: json['alcance'] as String? ?? 'GRUPOS_ASIGNADOS',
        generatedAt: DateTime.parse(json['generadoEn'] as String).toLocal(),
        summary: RiskSummary.fromJson(
          Map<String, dynamic>.from(json['resumen'] as Map? ?? const {}),
        ),
        alerts: _mapList(json['alertas'], StudentRiskAlert.fromJson),
      );
}

class TeacherDetailedDashboard {
  const TeacherDetailedDashboard({
    required this.analytics,
    required this.risks,
  });

  final TeacherDetailedAnalytics analytics;
  final TeacherRiskReport risks;
}

String institutionAreaLabel(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

DateTime? _optionalDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parser) =>
    (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
