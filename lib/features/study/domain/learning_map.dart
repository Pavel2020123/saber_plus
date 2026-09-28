import '../../academic/domain/academic_models.dart';

typedef LearningMapRequest = ({AcademicArea area, String subtopicId});

class LearningMapNode {
  const LearningMapNode(this.id, this.name, this.themeId, this.themeName);
  final String id;
  final String name;
  final String themeId;
  final String themeName;

  factory LearningMapNode.parse(Object? raw) {
    if (raw is! Map ||
        !validMapId(raw['id']) ||
        !validMapId(raw['temaId']) ||
        raw['nombre'] is! String ||
        raw['tema'] is! String) {
      throw const FormatException('Referencia del mapa inválida.');
    }
    return LearningMapNode(
      raw['id'] as String,
      raw['nombre'] as String,
      raw['temaId'] as String,
      raw['tema'] as String,
    );
  }
}

bool validMapId(Object? value) =>
    value is String && RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value);

class LearningMap {
  const LearningMap({
    required this.target,
    required this.previous,
    required this.route,
  });
  final LearningMapNode target;
  final List<LearningMapNode> previous;
  final List<LearningMapNode> route;

  factory LearningMap.parse(Object? raw, LearningMapRequest request) {
    if (raw is! Map ||
        raw['versionContrato'] != 1 ||
        raw['orientativo'] != true ||
        raw['area'] != request.area.backendValue ||
        raw['revision'] is! int ||
        (raw['revision'] as int) < 0) {
      throw const FormatException('Contrato del mapa inválido.');
    }
    final target = LearningMapNode.parse(raw['subtema']);
    if (target.id != request.subtopicId) {
      throw const FormatException('Destino incorrecto.');
    }
    List<LearningMapNode> nodes(String key, int max) {
      final value = raw[key];
      if (value is! List || value.length > max) {
        throw const FormatException('Lista inválida.');
      }
      final result = value.map(LearningMapNode.parse).toList();
      if (result.any((n) => n.id == target.id) ||
          result.map((n) => n.id).toSet().length != result.length) {
        throw const FormatException('Referencias repetidas.');
      }
      return List.unmodifiable(result);
    }

    final previous = nodes('previos', 8), route = nodes('recorrido', 5000);
    if (previous.any(
      (n) => !route.any((r) => r.id == n.id && r.themeId == n.themeId),
    )) {
      throw const FormatException('Recorrido incompleto.');
    }
    return LearningMap(target: target, previous: previous, route: route);
  }
}

abstract interface class LearningMapRepository {
  Future<LearningMap> load(LearningMapRequest request);
}
