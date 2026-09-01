import '../../academic/domain/academic_models.dart';
import '../domain/battle_models.dart';
import '../domain/battle_repository.dart';

class DemoBattleRepository implements BattleRepository {
  final Map<String, Map<String, dynamic>> _details = {};
  final Map<String, List<Map<String, dynamic>>> _questionBanks = {};
  final List<BlockedRival> _blocks = [];
  var _sequence = 0;

  @override
  Future<BattleDashboard> loadDashboard() async => BattleDashboard.fromJson({
    'resumen': {
      'jugadas': 3,
      'victorias': 2,
      'derrotas': 1,
      'empates': 0,
      'rachaActual': 1,
      'mejorRacha': 2,
      'xpBatallas': 95,
    },
    'batallas': _details.values.toList(growable: false),
    'privacidad': _privacy,
  });

  @override
  Future<BattleDetail> create({
    required BattleMode mode,
    AcademicArea? area,
    bool privateInvitation = false,
  }) async {
    _sequence += 1;
    final id = 'demo-batalla-$_sequence';
    final now = DateTime.now();
    final questions = _questions();
    _questionBanks[id] = questions;
    final detail = <String, dynamic>{
      'id': id,
      'modo': mode.backendValue,
      'area': area?.backendValue,
      'estado': privateInvitation ? 'PENDIENTE' : 'ACTIVA',
      'creadaEn': now.toUtc().toIso8601String(),
      'expiraEn': now.add(const Duration(hours: 24)).toUtc().toIso8601String(),
      'rival': privateInvitation ? null : {'alias': 'Rival anónimo'},
      'soyCreador': true,
      'codigoInvitacion': privateInvitation ? 'SABER123' : null,
      'progresoPropio': _progress(total: questions.length, hideScore: true),
      'progresoRival': privateInvitation
          ? null
          : _progress(total: questions.length, hideScore: true),
      'resultado': null,
      'xpGanado': 0,
      'privacidad': _privacy,
      'totalPreguntas': questions.length,
      'iniciadaEn': null,
      'finalizadaEn': null,
      'yo': {'alias': 'Tú'},
      'preguntas': <Map<String, dynamic>>[],
      'insigniasDesbloqueadas': <Map<String, dynamic>>[],
    };
    _details[id] = detail;
    return BattleDetail.fromJson(detail);
  }

  @override
  Future<BattleDetail> joinInvitation(String code) async {
    if (code.trim().toUpperCase() != 'SABER123') {
      throw StateError('En la demostración usa el código SABER123.');
    }
    return create(mode: BattleMode.ghostRace);
  }

  @override
  Future<BattleDetail> loadDetail(String battleId) async =>
      BattleDetail.fromJson(_required(battleId));

  @override
  Future<BattleDetail> start(String battleId) async {
    final detail = _required(battleId);
    detail['iniciadaEn'] = DateTime.now().toUtc().toIso8601String();
    detail['preguntas'] = _questionBanks[battleId]!;
    return BattleDetail.fromJson(detail);
  }

  @override
  Future<BattleDetail> answer({
    required String battleId,
    required String questionId,
    required String answerId,
  }) async {
    final detail = _required(battleId);
    final questions = (detail['preguntas'] as List<Map<String, dynamic>>);
    final question = questions.firstWhere((item) => item['id'] == questionId);
    question['respuestaPropiaId'] = answerId;
    final answered = questions.where(
      (item) => item['respuestaPropiaId'] != null,
    );
    final correct = answered.where(
      (item) => item['respuestaPropiaId'] == item['_correcta'],
    );
    detail['progresoPropio'] = _progress(
      total: questions.length,
      answered: answered.length,
      correct: correct.length,
      finished: answered.length == questions.length,
      hideScore: true,
    );
    if (answered.length == questions.length) return finish(battleId);
    return BattleDetail.fromJson(detail);
  }

  @override
  Future<BattleDetail> finish(String battleId) async {
    final detail = _required(battleId);
    final questions = (detail['preguntas'] as List<Map<String, dynamic>>);
    if (questions.any((item) => item['respuestaPropiaId'] == null)) {
      throw StateError('Completa las preguntas antes de finalizar.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    detail['estado'] = 'FINALIZADA';
    detail['finalizadaEn'] = now;
    detail['resultado'] = 'VICTORIA';
    detail['xpGanado'] = 40;
    final correct = questions
        .where((item) => item['respuestaPropiaId'] == item['_correcta'])
        .length;
    detail['progresoPropio'] = _progress(
      total: questions.length,
      answered: questions.length,
      correct: correct,
      finished: true,
    );
    detail['progresoRival'] = _progress(
      total: questions.length,
      answered: questions.length,
      correct: 1,
      finished: true,
    );
    for (final question in questions) {
      final correctId = question['_correcta'] as String;
      question['respuestaCorrectaId'] = correctId;
      question['esCorrecta'] = question['respuestaPropiaId'] == correctId;
      question['explicacion'] =
          'Revisa el procedimiento y compáralo con tu respuesta.';
    }
    return BattleDetail.fromJson(detail);
  }

  @override
  Future<BattleDetail> cancel(String battleId) async {
    final detail = _required(battleId);
    detail['estado'] = 'CANCELADA';
    detail['codigoInvitacion'] = null;
    return BattleDetail.fromJson(detail);
  }

  @override
  Future<void> blockRival(String battleId) async {
    _required(battleId);
    _sequence += 1;
    _blocks.add(
      BlockedRival(
        id: 'demo-bloqueo-$_sequence',
        alias: 'Rival bloqueado',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> report({
    required String battleId,
    required BattleReportReason reason,
    String? details,
  }) async {
    _required(battleId);
  }

  @override
  Future<List<BlockedRival>> loadBlocks() async => List.unmodifiable(_blocks);

  @override
  Future<void> unblock(String blockId) async {
    _blocks.removeWhere((item) => item.id == blockId);
  }

  Map<String, dynamic> _required(String id) {
    final detail = _details[id];
    if (detail == null) throw StateError('Batalla demostrativa no encontrada.');
    return detail;
  }
}

const _privacy = {
  'identidadesProtegidas': true,
  'chatHabilitado': false,
  'datosRivalPublicados': ['alias', 'progreso'],
};

Map<String, dynamic> _progress({
  required int total,
  int answered = 0,
  int correct = 0,
  bool finished = false,
  bool hideScore = false,
}) => {
  'respondidas': answered,
  'correctas': hideScore ? null : correct,
  'totalPreguntas': total,
  'energia': hideScore
      ? null
      : total == 0
      ? 0
      : ((correct / total) * 100).round(),
  'vidas': 3,
  'finalizo': finished,
};

List<Map<String, dynamic>> _questions() => [
  {
    'id': 'demo-pregunta-1',
    'enunciado': 'Si 3 cuadernos cuestan 18.000 pesos, ¿cuánto cuestan 5?',
    'contexto': 'Aplica proporcionalidad directa.',
    'imagenUrl': null,
    'opciones': [
      {'id': 'demo-1-a', 'texto': '24.000 pesos'},
      {'id': 'demo-1-b', 'texto': '30.000 pesos'},
      {'id': 'demo-1-c', 'texto': '36.000 pesos'},
      {'id': 'demo-1-d', 'texto': '40.000 pesos'},
    ],
    'respuestaPropiaId': null,
    '_correcta': 'demo-1-b',
  },
  {
    'id': 'demo-pregunta-2',
    'enunciado': '¿Cuál es el propósito principal de una conclusión?',
    'contexto': null,
    'imagenUrl': null,
    'opciones': [
      {'id': 'demo-2-a', 'texto': 'Introducir un tema distinto'},
      {'id': 'demo-2-b', 'texto': 'Resumir y cerrar la idea central'},
      {'id': 'demo-2-c', 'texto': 'Eliminar los argumentos'},
      {'id': 'demo-2-d', 'texto': 'Cambiar la postura del autor'},
    ],
    'respuestaPropiaId': null,
    '_correcta': 'demo-2-b',
  },
];
