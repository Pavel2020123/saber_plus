import '../../../academic/domain/academic_models.dart';
import '../../trivia_rush/domain/trivia_rush_models.dart';

class GhostDuelConfig {
  const GhostDuelConfig({required this.areas, required this.duration});

  final List<AcademicArea> areas;
  final TriviaRushDuration duration;

  TriviaRushConfig get triviaConfig =>
      TriviaRushConfig(areas: areas, duration: duration);

  String get routeLocation => Uri(
    path: '/student/practice/ghost-duel/play',
    queryParameters: {
      'areas': areas.map((area) => area.backendValue).join(','),
      'segundos': duration.seconds.toString(),
    },
  ).toString();

  static GhostDuelConfig? tryFromUri(Uri uri) {
    final trivia = TriviaRushConfig.tryFromUri(uri);
    if (trivia == null) return null;
    return GhostDuelConfig(areas: trivia.areas, duration: trivia.duration);
  }
}

class GhostDuelKey {
  GhostDuelKey({required Iterable<AcademicArea> areas, required this.seconds})
    : areas = List.unmodifiable(
        <AcademicArea>[...areas]..sort(
          (left, right) => left.backendValue.compareTo(right.backendValue),
        ),
      ) {
    if (this.areas.isEmpty) {
      throw ArgumentError.value(areas, 'areas', 'No puede estar vacío.');
    }
    if (seconds <= 0) {
      throw RangeError.value(seconds, 'seconds', 'Debe ser positivo.');
    }
  }

  factory GhostDuelKey.fromTriviaConfig(TriviaRushConfig config) =>
      GhostDuelKey(areas: config.areas, seconds: config.duration.seconds);

  final List<AcademicArea> areas;
  final int seconds;

  String get storageKey =>
      '${areas.map((area) => area.backendValue).join('-')}.$seconds';

  Map<String, dynamic> toJson() => {
    'areas': areas.map((area) => area.backendValue).toList(growable: false),
    'seconds': seconds,
  };

  factory GhostDuelKey.fromJson(Map<String, dynamic> json) => GhostDuelKey(
    areas: (json['areas'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(AcademicArea.fromBackend),
    seconds: json['seconds'] as int? ?? 0,
  );
}

class GhostCheckpoint {
  const GhostCheckpoint({required this.elapsedSeconds, required this.score});

  final int elapsedSeconds;
  final int score;

  Map<String, dynamic> toJson() => {
    'elapsedSeconds': elapsedSeconds,
    'score': score,
  };

  factory GhostCheckpoint.fromJson(Map<String, dynamic> json) =>
      GhostCheckpoint(
        elapsedSeconds: (json['elapsedSeconds'] as int? ?? 0).clamp(0, 7200),
        score: (json['score'] as int? ?? 0).clamp(0, 100000000),
      );
}

class GhostRun {
  GhostRun({
    required this.userId,
    required this.key,
    required this.score,
    required this.bestCombo,
    required this.correctAnswers,
    required this.completedAt,
    required Iterable<GhostCheckpoint> checkpoints,
    this.assisted = false,
    this.sourceAttemptId,
  }) : checkpoints = List.unmodifiable(
         [...checkpoints]..sort(
           (left, right) => left.elapsedSeconds.compareTo(right.elapsedSeconds),
         ),
       );

  final String userId;
  final GhostDuelKey key;
  final int score;
  final int bestCombo;
  final int correctAnswers;
  final DateTime completedAt;
  final List<GhostCheckpoint> checkpoints;
  final bool assisted;
  final String? sourceAttemptId;

  int scoreAt(int elapsedSeconds) {
    var result = 0;
    for (final checkpoint in checkpoints) {
      if (checkpoint.elapsedSeconds > elapsedSeconds) break;
      result = checkpoint.score;
    }
    return result;
  }

  bool isBetterThan(GhostRun other) {
    if (score != other.score) return score > other.score;
    if (correctAnswers != other.correctAnswers) {
      return correctAnswers > other.correctAnswers;
    }
    if (bestCombo != other.bestCombo) return bestCombo > other.bestCombo;
    return completedAt.isAfter(other.completedAt);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'userId': userId,
    'key': key.toJson(),
    'score': score,
    'bestCombo': bestCombo,
    'correctAnswers': correctAnswers,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'checkpoints': checkpoints
        .map((checkpoint) => checkpoint.toJson())
        .toList(growable: false),
    'assisted': assisted,
    'sourceAttemptId': ?sourceAttemptId,
  };

  factory GhostRun.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Versión de fantasma no compatible.');
    }
    final userId = json['userId'] as String? ?? '';
    final completedAt = DateTime.tryParse(json['completedAt'] as String? ?? '');
    if (userId.isEmpty || completedAt == null) {
      throw const FormatException('Récord fantasma incompleto.');
    }
    return GhostRun(
      userId: userId,
      key: GhostDuelKey.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      score: (json['score'] as int? ?? 0).clamp(0, 100000000),
      bestCombo: (json['bestCombo'] as int? ?? 0).clamp(0, 100000),
      correctAnswers: (json['correctAnswers'] as int? ?? 0).clamp(0, 100000),
      completedAt: completedAt.toLocal(),
      checkpoints: (json['checkpoints'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => GhostCheckpoint.fromJson(Map<String, dynamic>.from(item)),
          ),
      assisted: json['assisted'] as bool? ?? false,
      sourceAttemptId: json['sourceAttemptId'] as String?,
    );
  }
}

enum GhostDuelOutcome { firstRecord, newRecord, keptRecord }

class GhostSaveResult {
  const GhostSaveResult({required this.outcome, required this.bestRun});

  final GhostDuelOutcome outcome;
  final GhostRun bestRun;
}
