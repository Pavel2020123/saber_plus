import 'dart:math';
import '../../academic/domain/academic_models.dart';

String newPriorityRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

Map<String, dynamic> priorityMap(Object? value) {
  if (value is! Map) throw const FormatException('Objeto inválido');
  return Map<String, dynamic>.from(value);
}

String priorityText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Texto inválido');
  }
  return value;
}

int priorityInt(Object? value, int max) {
  if (value is! int || value < 0 || value > max) {
    throw const FormatException('Conteo inválido');
  }
  return value;
}

DateTime priorityDate(Object? value) {
  final text = priorityText(value);
  if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(text)) {
    throw const FormatException('Falta zona horaria');
  }
  return DateTime.parse(text).toUtc();
}

class PriorityProgress {
  const PriorityProgress({required this.count, required this.applies});
  final int count;
  final bool applies;
  bool get complete => applies && count == 5;
  String get label => !applies
      ? 'No aplica'
      : complete
      ? 'Práctica cumplida · 5/5'
      : 'Práctica · $count/5';
  factory PriorityProgress.fromJson(Map<String, dynamic> json) {
    final count = priorityInt(json['preguntasPracticadas'], 5);
    final applies = json['aplica'];
    if (applies is! bool ||
        json['metaPreguntas'] != 5 ||
        json['acreditaDominio'] != false ||
        json['cumplida'] != (applies && count == 5) ||
        (!applies && count != 0) ||
        json['estadoCumplimiento'] !=
            (!applies
                ? 'NO_APLICA'
                : count == 5
                ? 'CUMPLIDA'
                : 'PENDIENTE')) {
      throw const FormatException('Cumplimiento incoherente');
    }
    return PriorityProgress(count: count, applies: applies);
  }
}

class TeacherPriority {
  const TeacherPriority({
    required this.id,
    required this.groupId,
    required this.area,
    required this.topicId,
    required this.topicName,
    this.subtopicId,
    this.subtopicName,
    required this.createdAt,
    required this.dueAt,
    this.withdrawnAt,
    this.groupName,
    this.progress,
    this.contentAvailable = true,
  });
  final String id, groupId, topicId, topicName;
  final String? subtopicId, subtopicName, groupName;
  final AcademicArea area;
  final DateTime createdAt, dueAt;
  final DateTime? withdrawnAt;
  final PriorityProgress? progress;
  final bool contentAvailable;
  bool get active => withdrawnAt == null && dueAt.isAfter(DateTime.now());
  String get stateLabel => withdrawnAt != null
      ? 'Retirada'
      : active
      ? 'Activa'
      : 'Vencida';
  String get title => subtopicName ?? topicName;
  factory TeacherPriority.fromJson(Map<String, dynamic> json) {
    final topic = priorityMap(json['tema']);
    final subtopic = json['subtema'] == null
        ? null
        : priorityMap(json['subtema']);
    final created = priorityDate(json['creadoEn']);
    final due = priorityDate(json['venceEn']);
    final withdrawn = json['retiradoEn'] == null
        ? null
        : priorityDate(json['retiradoEn']);
    if (json['metaPreguntas'] != 5 ||
        !due.isAfter(created) ||
        due.difference(created) > const Duration(days: 30) ||
        (withdrawn != null && withdrawn.isBefore(created)) ||
        !{'ACTIVA', 'RETIRADA', 'VENCIDA'}.contains(json['estado']) ||
        (json['estado'] == 'RETIRADA') != (withdrawn != null) ||
        (json.containsKey('contenidoPublicadoSuficiente') &&
            json['contenidoPublicadoSuficiente'] is! bool)) {
      throw const FormatException('Prioridad incoherente');
    }
    return TeacherPriority(
      id: priorityText(json['id']),
      groupId: priorityText(json['grupoId']),
      area: AcademicArea.fromBackend(priorityText(json['area'])),
      topicId: priorityText(topic['id']),
      topicName: priorityText(topic['nombre']),
      subtopicId: subtopic == null ? null : priorityText(subtopic['id']),
      subtopicName: subtopic == null ? null : priorityText(subtopic['nombre']),
      createdAt: created,
      dueAt: due,
      withdrawnAt: withdrawn,
      groupName: json['grupoNombre'] as String?,
      progress: json.containsKey('aplica')
          ? PriorityProgress.fromJson(json)
          : null,
      contentAvailable: json['contenidoPublicadoSuficiente'] as bool? ?? true,
    );
  }
}

class PriorityCatalogEntry {
  const PriorityCatalogEntry({
    required this.id,
    required this.name,
    required this.topicId,
    required this.topicName,
    required this.area,
    required this.count,
  });
  final String id, name, topicId, topicName;
  final AcademicArea area;
  final int count;
  bool get assignable => count >= 5 && count <= 2000;
  factory PriorityCatalogEntry.fromJson(Map<String, dynamic> json) {
    final topic = priorityMap(json['tema']);
    final result = PriorityCatalogEntry(
      id: priorityText(json['id']),
      name: priorityText(json['nombre']),
      topicId: priorityText(topic['id']),
      topicName: priorityText(topic['nombre']),
      area: AcademicArea.fromBackend(priorityText(topic['area'])),
      count: priorityInt(json['preguntasPublicadas'], 10000000),
    );
    if (json['asignable'] != result.assignable) {
      throw const FormatException('Catálogo incoherente');
    }
    return result;
  }
}

class PriorityStudent {
  const PriorityStudent(this.id, this.name, this.progress);
  final String id, name;
  final PriorityProgress progress;
  factory PriorityStudent.fromJson(Map<String, dynamic> json) =>
      PriorityStudent(
        priorityText(json['id']),
        priorityText(json['nombre']),
        PriorityProgress.fromJson(json),
      );
}

enum PriorityView { teacher, student, catalog, report }

typedef PriorityQuery = ({
  PriorityView view,
  String? groupId,
  String? priorityId,
  AcademicArea? area,
  int page,
});

class PriorityBundle {
  const PriorityBundle({
    this.priorities = const [],
    this.catalog = const [],
    this.students = const [],
    this.priority,
    this.page = 1,
    this.hasMore = false,
    this.contentAvailable = true,
  });
  final List<TeacherPriority> priorities;
  final List<PriorityCatalogEntry> catalog;
  final List<PriorityStudent> students;
  final TeacherPriority? priority;
  final int page;
  final bool hasMore, contentAvailable;
  factory PriorityBundle.fromJson(
    Map<String, dynamic> json,
    PriorityQuery query,
  ) {
    if (json['version'] != 1 ||
        json['pagina'] != query.page ||
        json['hayMas'] is! bool) {
      throw const FormatException('Página inválida');
    }
    final policy = priorityMap(json['politica']);
    if (policy['metaPreguntas'] != 5 ||
        policy['acreditaDominio'] != false ||
        policy['version'] != 1) {
      throw const FormatException('Política desconocida');
    }
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) convert) {
      final rows = json[key];
      if (rows is! List || rows.length > 20) {
        throw const FormatException('Listado inválido');
      }
      return List.unmodifiable(rows.map((v) => convert(priorityMap(v))));
    }

    final priorities =
        query.view == PriorityView.teacher || query.view == PriorityView.student
        ? parse('prioridades', TeacherPriority.fromJson)
        : const <TeacherPriority>[];
    if (priorities.any(
      (p) =>
          (query.groupId != null && p.groupId != query.groupId) ||
          (query.view == PriorityView.student && p.progress == null),
    )) {
      throw const FormatException('Alcance inesperado');
    }
    final priority = query.view == PriorityView.report
        ? TeacherPriority.fromJson(priorityMap(json['prioridad']))
        : null;
    if (priority != null &&
        (priority.id != query.priorityId ||
            priority.groupId != query.groupId ||
            json['contenidoPublicadoSuficiente'] is! bool)) {
      throw const FormatException('Informe inesperado');
    }
    final catalog = query.view == PriorityView.catalog
        ? parse('subtemas', PriorityCatalogEntry.fromJson)
        : const <PriorityCatalogEntry>[];
    if (query.area != null && catalog.any((e) => e.area != query.area)) {
      throw const FormatException('Área inesperada');
    }
    return PriorityBundle(
      priorities: priorities,
      catalog: catalog,
      students: query.view == PriorityView.report
          ? parse('estudiantes', PriorityStudent.fromJson)
          : const [],
      priority: priority,
      page: query.page,
      hasMore: json['hayMas'] as bool,
      contentAvailable: json['contenidoPublicadoSuficiente'] as bool? ?? true,
    );
  }
}

class PriorityCreation {
  PriorityCreation({
    required this.groupId,
    required this.topicId,
    this.subtopicId,
    required DateTime dueAt,
    String? id,
  }) : id = id ?? newPriorityRequestId(),
       dueAt = DateTime.fromMillisecondsSinceEpoch(
         dueAt.toUtc().millisecondsSinceEpoch,
         isUtc: true,
       );
  final String id, groupId, topicId;
  final String? subtopicId;
  final DateTime dueAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'temaId': topicId,
    if (subtopicId != null) 'subtemaId': subtopicId,
    'venceEn': dueAt.toUtc().toIso8601String(),
  };
}
