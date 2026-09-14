const studyMetricKeys = [
  'segundosEvaluaciones',
  'segundosPomodoroDeclarados',
  'respuestas',
  'aciertos',
  'errores',
  'respuestasSinTiempo',
  'sesionesEvaluacion',
  'bloquesPomodoro',
];
const studyTimePolicy = <String, Object>{
  'version': 1,
  'zonaHoraria': 'America/Bogota',
  'duracionPomodoroSegundos': 1500,
  'diasMaximosSincronizacion': 90,
  'maximoEventosPorLote': 50,
  'maximoRegistrosEvaluacion': 10000,
  'fuentesNoSumables': true,
  'acreditaAtencion': false,
  'acreditaDominio': false,
  'otorgaXp': false,
  'criterioEvaluacion': 'PRIMER_REGISTRO_POR_SESION_Y_PREGUNTA',
  'criterioDia': 'FECHA_DE_CONFIRMACION_O_FINALIZACION',
  'medicionEvaluaciones': 'TIEMPOS_DECLARADOS_EN_RESPUESTAS_CONFIRMADAS',
  'medicionPomodoro': 'BLOQUES_COMPLETADOS_DECLARADOS_POR_DISPOSITIVO',
};
Map<String, dynamic> studyMap(Object? value) {
  if (value is! Map) throw const FormatException('Objeto de tiempo inválido');
  return Map<String, dynamic>.from(value);
}

void validateStudyPolicy(Object? raw) {
  final policy = studyMap(raw);
  for (final entry in studyTimePolicy.entries) {
    if (policy[entry.key] != entry.value) {
      throw const FormatException('Política de tiempo incompatible');
    }
  }
}

int studyCount(Object? value, {int max = 1000000000}) {
  if (value is! int || value < 0 || value > max) {
    throw const FormatException('Métrica inválida');
  }
  return value;
}

DateTime studyInstant(Object? value) {
  if (value is! String ||
      !RegExp(r'T.*(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw const FormatException('Fecha sin zona');
  }
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('Fecha inválida');
  return date.toUtc();
}

String colombianStudyDay(DateTime date) => date
    .toUtc()
    .subtract(const Duration(hours: 5))
    .toIso8601String()
    .substring(0, 10);

class StudyMetrics {
  StudyMetrics._(this.values);
  final Map<String, int> values;
  int operator [](String key) => values[key]!;
  int get evaluationSeconds => this['segundosEvaluaciones'];
  int get pomodoroSeconds => this['segundosPomodoroDeclarados'];
  int get answers => this['respuestas'];
  factory StudyMetrics.fromJson(Object? raw) {
    final json = studyMap(raw);
    final values = {for (final k in studyMetricKeys) k: studyCount(json[k])};
    if (values['respuestas']! > 10000 ||
        values['aciertos']! + values['errores']! != values['respuestas'] ||
        values['respuestasSinTiempo']! > values['respuestas']! ||
        values['sesionesEvaluacion']! > values['respuestas']! ||
        values['segundosPomodoroDeclarados'] !=
            values['bloquesPomodoro']! * 1500 ||
        values['segundosEvaluaciones']! >
            (values['respuestas']! - values['respuestasSinTiempo']!) * 7200) {
      throw const FormatException('Totales de tiempo incoherentes');
    }
    return StudyMetrics._(Map.unmodifiable(values));
  }
}

class StudyDay {
  const StudyDay(this.date, this.metrics, this.state, this.percentage);
  final String date, state;
  final StudyMetrics metrics;
  final double? percentage;
}

class StudyEvolution {
  const StudyEvolution({
    required this.days,
    required this.since,
    required this.until,
    required this.partial,
    required this.total,
    required this.evolution,
    this.studentName,
    this.isDemo = false,
  });
  final int days;
  final DateTime since, until;
  final bool partial, isDemo;
  final String? studentName;
  final StudyMetrics total;
  final List<StudyDay> evolution;

  factory StudyEvolution.fromJson(
    Map<String, dynamic> envelope,
    int expectedDays, {
    String? studentId,
    bool demo = false,
  }) {
    var json = envelope;
    String? name;
    if (studentId != null) {
      final student = studyMap(envelope['estudiante']);
      if (envelope['version'] != 1 ||
          student['id'] != studentId ||
          student['nombre'] is! String ||
          (student['nombre'] as String).trim().isEmpty ||
          student['grupos'] is! List) {
        throw const FormatException('Ficha de otro estudiante');
      }
      for (final raw in student['grupos'] as List) {
        final group = studyMap(raw);
        if (group['id'] is! String || group['nombre'] is! String) {
          throw const FormatException('Grupo inválido');
        }
      }
      name = student['nombre'] as String;
      json = studyMap(envelope['evolucion']);
    }
    validateStudyPolicy(json['politica']);
    if (![7, 30, 90].contains(expectedDays) ||
        json['version'] != 1 ||
        json['dias'] != expectedDays ||
        json['parcial'] is! bool ||
        json['evolucion'] is! List ||
        (json['evolucion'] as List).length != expectedDays) {
      throw const FormatException('Ventana de estudio incompatible');
    }
    final since = studyInstant(json['desde']),
        until = studyInstant(json['hasta']);
    final partial = json['parcial'] as bool;
    final readCount = studyCount(json['registrosEvaluacionLeidos'], max: 10000);
    if (until.isBefore(since) ||
        since != DateTime.parse('${colombianStudyDay(since)}T00:00:00-05:00') ||
        colombianStudyDay(since.add(Duration(days: expectedDays - 1))) !=
            colombianStudyDay(until) ||
        (partial && readCount != 10000)) {
      throw const FormatException('Fechas o muestra incompatibles');
    }
    final total = StudyMetrics.fromJson(json['totales']);
    final rows = <StudyDay>[];
    final sums = {for (final key in studyMetricKeys) key: 0};
    for (var i = 0; i < expectedDays; i++) {
      final row = studyMap((json['evolucion'] as List)[i]);
      final metrics = StudyMetrics.fromJson(row);
      final date = colombianStudyDay(since.add(Duration(days: i)));
      final state = partial
          ? 'MUESTRA_PARCIAL'
          : metrics.answers > 0 || metrics['bloquesPomodoro'] > 0
          ? 'CON_REGISTROS'
          : 'SIN_REGISTROS';
      final rawPercentage = row['porcentajeAciertos'];
      final expectedPercentage = !partial && metrics.answers > 0
          ? (metrics['aciertos'] * 1000 / metrics.answers).round() / 10
          : null;
      if (row['fecha'] != date ||
          row['estado'] != state ||
          rawPercentage != expectedPercentage) {
        throw const FormatException('Día o porcentaje incoherente');
      }
      for (final k in studyMetricKeys) {
        sums[k] = sums[k]! + metrics[k];
      }
      rows.add(StudyDay(date, metrics, state, expectedPercentage));
    }
    for (final k in studyMetricKeys) {
      if (k == 'sesionesEvaluacion') {
        if (total[k] > sums[k]! || rows.any((d) => d.metrics[k] > total[k])) {
          throw const FormatException('Sesiones incoherentes');
        }
      } else if (total[k] != sums[k]) {
        throw const FormatException('Sumatoria incoherente');
      }
    }
    if (total.answers > readCount) {
      throw const FormatException('Muestra incoherente');
    }
    return StudyEvolution(
      days: expectedDays,
      since: since,
      until: until,
      partial: partial,
      total: total,
      evolution: List.unmodifiable(rows),
      studentName: name,
      isDemo: demo,
    );
  }
}
