import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/star_rescue_models.dart';

class StarRescueResume {
  const StarRescueResume(this.attemptId, [this.pending]);
  final String attemptId;
  final StarRescuePendingAnswer? pending;
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'pending': pending?.toJson(),
  };
  factory StarRescueResume.fromJson(Map<String, dynamic> json) {
    final id = json['attemptId'] as String;
    final pending = json['pending'] == null
        ? null
        : StarRescuePendingAnswer.fromJson(
            Map<String, dynamic>.from(json['pending'] as Map),
          );
    if (id.isEmpty || (pending != null && pending.attemptId != id)) {
      throw const FormatException('Registro de recuperación inválido.');
    }
    return StarRescueResume(id, pending);
  }
}

/// Stores only attempt/submission identifiers, never bank content or solutions.
class StarRescueResumeStore {
  StarRescueResumeStore({required this.readValue, required this.writeValue});
  final Future<String?> Function(String key) readValue;
  final Future<void> Function(String key, String value) writeValue;
  String key(String scope) =>
      'saberplus_star_rescue_v1_${base64Url.encode(utf8.encode(scope))}';

  Future<StarRescueResume?> read(String scope) async {
    final raw = await readValue(key(scope));
    if (raw == null || raw == 'null') return null;
    // Do not silently discard a failed/corrupt pending write and send another option.
    return StarRescueResume.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> save(String scope, StarRescueResume? value) =>
      writeValue(key(scope), jsonEncode(value?.toJson()));
}

final starRescueResumeStoreProvider = Provider<StarRescueResumeStore>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  return StarRescueResumeStore(
    readValue: (key) => storage.read(key: key),
    writeValue: (key, value) => storage.write(key: key, value: value),
  );
});
