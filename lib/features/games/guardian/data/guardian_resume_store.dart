import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/guardian_models.dart';

class GuardianResume {
  const GuardianResume(this.attemptId, [this.pending, this.isCompetitive]);
  final String attemptId;
  final GuardianPendingAnswer? pending;
  final bool? isCompetitive;
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'pending': pending?.toJson(),
    if (isCompetitive != null) 'competitive': isCompetitive,
  };
  factory GuardianResume.fromJson(Map<String, dynamic> json) {
    final id = json['attemptId'] as String;
    if (json.containsKey('competitive') && json['competitive'] is! bool) {
      throw const FormatException('Modalidad guardada inválida.');
    }
    final pending = json['pending'] == null
        ? null
        : GuardianPendingAnswer.fromJson(
            Map<String, dynamic>.from(json['pending'] as Map),
          );
    if (id.isEmpty || (pending != null && pending.attemptId != id)) {
      throw const FormatException('Registro de recuperación inválido.');
    }
    return GuardianResume(id, pending, json['competitive'] as bool?);
  }
}

/// Only identifiers/keys, not question content, solutions, tokens or XP.
class GuardianResumeStore {
  GuardianResumeStore({required this.readValue, required this.writeValue});
  final Future<String?> Function(String key) readValue;
  final Future<void> Function(String key, String value) writeValue;
  String key(String scope) =>
      'saberplus_guardian_v1_${base64Url.encode(utf8.encode(scope))}';
  Future<GuardianResume?> read(String scope) async {
    final raw = await readValue(key(scope));
    if (raw == null || raw == 'null') return null;
    // Fail closed: never discard a corrupt pending answer and send another one.
    return GuardianResume.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> save(String scope, GuardianResume? value) =>
      writeValue(key(scope), jsonEncode(value?.toJson()));
}

final guardianResumeStoreProvider = Provider<GuardianResumeStore>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  return GuardianResumeStore(
    readValue: (key) => storage.read(key: key),
    writeValue: (key, value) => storage.write(key: key, value: value),
  );
});
