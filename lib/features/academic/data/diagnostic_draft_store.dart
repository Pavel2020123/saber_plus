import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiagnosticDraft {
  const DiagnosticDraft({
    required this.diagnosticId,
    this.selectedAnswers = const {},
    this.responseTimesSeconds = const {},
    this.currentQuestionIndex = 0,
  });

  final String diagnosticId;
  final Map<String, String> selectedAnswers;
  final Map<String, int> responseTimesSeconds;
  final int currentQuestionIndex;

  Map<String, dynamic> toJson() => {
    'diagnosticId': diagnosticId,
    'selectedAnswers': selectedAnswers,
    'responseTimesSeconds': responseTimesSeconds,
    'currentQuestionIndex': currentQuestionIndex,
  };

  factory DiagnosticDraft.fromJson(Map<String, dynamic> json) {
    final selected = json['selectedAnswers'];
    final times = json['responseTimesSeconds'];
    return DiagnosticDraft(
      diagnosticId: json['diagnosticId'] as String,
      selectedAnswers: selected is Map
          ? selected.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
      responseTimesSeconds: times is Map
          ? times.map(
              (key, value) =>
                  MapEntry(key.toString(), value is num ? value.toInt() : 0),
            )
          : const {},
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
    );
  }
}

class DiagnosticDraftStore {
  DiagnosticDraftStore(this._storage);

  static const _keyPrefix = 'saberplus_diagnostic_draft_';
  final FlutterSecureStorage _storage;

  Future<DiagnosticDraft?> read(String diagnosticId) async {
    try {
      final encoded = await _storage.read(key: '$_keyPrefix$diagnosticId');
      if (encoded == null) return null;
      final json = jsonDecode(encoded);
      if (json is! Map) return null;
      final draft = DiagnosticDraft.fromJson(Map<String, dynamic>.from(json));
      return draft.diagnosticId == diagnosticId ? draft : null;
    } on MissingPluginException {
      return null;
    } on FormatException {
      await clear(diagnosticId);
      return null;
    } on TypeError {
      await clear(diagnosticId);
      return null;
    }
  }

  Future<void> save(DiagnosticDraft draft) async {
    try {
      await _storage.write(
        key: '$_keyPrefix${draft.diagnosticId}',
        value: jsonEncode(draft.toJson()),
      );
    } on MissingPluginException {
      // Los widget tests no cargan los plugins nativos.
    }
  }

  Future<void> clear(String diagnosticId) async {
    try {
      await _storage.delete(key: '$_keyPrefix$diagnosticId');
    } on MissingPluginException {
      // Los widget tests no cargan los plugins nativos.
    }
  }
}

final diagnosticDraftStoreProvider = Provider<DiagnosticDraftStore>(
  (ref) => DiagnosticDraftStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ),
);
