import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/practice_models.dart';

class PracticeDraft {
  const PracticeDraft({
    required this.session,
    required this.selectedAnswers,
    required this.responseTimesSeconds,
    required this.currentIndex,
    required this.startedAt,
    required this.expiresAt,
    this.focusLossCount = 0,
  });

  final PracticeSession session;
  final Map<String, String> selectedAnswers;
  final Map<String, int> responseTimesSeconds;
  final int currentIndex;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int focusLossCount;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  factory PracticeDraft.fromJson(Map<String, dynamic> json) => PracticeDraft(
    session: PracticeSession.fromStoredJson(
      Map<String, dynamic>.from(json['session'] as Map),
    ),
    selectedAnswers: Map<String, dynamic>.from(
      json['selectedAnswers'] as Map? ?? const {},
    ).map((key, value) => MapEntry(key, value as String)),
    responseTimesSeconds:
        Map<String, dynamic>.from(
          json['responseTimesSeconds'] as Map? ?? const {},
        ).map(
          (key, value) =>
              MapEntry(key, value is num ? value.toInt().clamp(0, 7200) : 0),
        ),
    currentIndex: json['currentIndex'] as int? ?? 0,
    startedAt: DateTime.parse(json['startedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    focusLossCount: (json['focusLossCount'] as num? ?? 0).toInt().clamp(0, 999),
  );

  Map<String, dynamic> toJson() => {
    'session': session.toStoredJson(),
    'selectedAnswers': selectedAnswers,
    'responseTimesSeconds': responseTimesSeconds,
    'currentIndex': currentIndex,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'focusLossCount': focusLossCount,
  };
}

class PracticeDraftStore {
  PracticeDraftStore(this._storage);

  static const _prefix = 'saberplus_practice_draft_';
  final FlutterSecureStorage _storage;

  Future<PracticeDraft?> read(String userId, String draftId) async {
    final key = _key(userId, draftId);
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return PracticeDraft.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } on MissingPluginException {
      return null;
    } on Object {
      await clear(userId, draftId);
      return null;
    }
  }

  Future<void> save(String userId, String draftId, PracticeDraft draft) async {
    try {
      await _storage.write(
        key: _key(userId, draftId),
        value: jsonEncode(draft.toJson()),
      );
    } on MissingPluginException {
      // Los widget tests sin plugins nativos continúan sin persistencia.
    }
  }

  Future<void> clear(String userId, String draftId) async {
    try {
      await _storage.delete(key: _key(userId, draftId));
    } on MissingPluginException {
      // Los widget tests sin plugins nativos continúan sin persistencia.
    }
  }

  String _key(String userId, String draftId) {
    final identity = base64Url.encode(utf8.encode('$userId\u0000$draftId'));
    return '$_prefix$identity';
  }
}

final practiceDraftStoreProvider = Provider<PracticeDraftStore>(
  (ref) => PracticeDraftStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ),
);
