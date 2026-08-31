import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ghost_duel_models.dart';
import '../domain/ghost_duel_repository.dart';

typedef GhostRecordReader = Future<String?> Function(String key);
typedef GhostRecordWriter = Future<void> Function(String key, String value);

class SharedPreferencesGhostDuelRepository implements GhostDuelRepository {
  SharedPreferencesGhostDuelRepository([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync(),
      _reader = null,
      _writer = null;

  factory SharedPreferencesGhostDuelRepository.withStorage({
    required GhostRecordReader reader,
    required GhostRecordWriter writer,
  }) => SharedPreferencesGhostDuelRepository._withStorage(reader, writer);

  SharedPreferencesGhostDuelRepository._withStorage(this._reader, this._writer)
    : _preferences = null;

  static const _prefix = 'saberplus.ghost-duel.v1.';

  final SharedPreferencesAsync? _preferences;
  final GhostRecordReader? _reader;
  final GhostRecordWriter? _writer;

  Future<String?> _read(String key) =>
      _reader?.call(key) ?? _preferences!.getString(key);

  Future<void> _write(String key, String value) =>
      _writer?.call(key, value) ?? _preferences!.setString(key, value);

  String _storageKey(String userId, GhostDuelKey key) =>
      '$_prefix${Uri.encodeComponent(userId)}.${key.storageKey}';

  @override
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  }) async {
    if (userId.trim().isEmpty) return null;
    final raw = await _read(_storageKey(userId, key));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final run = GhostRun.fromJson(Map<String, dynamic>.from(decoded));
      if (run.userId != userId || run.key.storageKey != key.storageKey) {
        return null;
      }
      return run;
    } on Object {
      return null;
    }
  }

  @override
  Future<GhostSaveResult> saveIfBetter(GhostRun run) async {
    if (run.assisted) {
      throw ArgumentError.value(
        run.assisted,
        'assisted',
        'Una partida asistida no puede crear un récord.',
      );
    }
    final previous = await loadBest(userId: run.userId, key: run.key);
    if (previous != null && !run.isBetterThan(previous)) {
      return GhostSaveResult(
        outcome: GhostDuelOutcome.keptRecord,
        bestRun: previous,
      );
    }
    await _write(_storageKey(run.userId, run.key), jsonEncode(run.toJson()));
    return GhostSaveResult(
      outcome: previous == null
          ? GhostDuelOutcome.firstRecord
          : GhostDuelOutcome.newRecord,
      bestRun: run,
    );
  }
}
