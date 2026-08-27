import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  SecureSessionStore(this._storage);

  static const _refreshTokenKey = 'saberplus_refresh_token';
  final FlutterSecureStorage _storage;

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } on MissingPluginException {
      // Los widget tests no cargan los plugins nativos.
    }
  }
}

final secureSessionStoreProvider = Provider<SecureSessionStore>(
  (ref) => SecureSessionStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ),
);
