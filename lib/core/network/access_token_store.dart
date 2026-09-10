import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessTokenStore {
  String? _accessToken;
  int _revision = 0;

  String? get accessToken => _accessToken;
  int get revision => _revision;

  void set(String token) {
    _accessToken = token;
    _revision++;
  }

  void clear() {
    _accessToken = null;
    _revision++;
  }
}

final accessTokenStoreProvider = Provider<AccessTokenStore>(
  (ref) => AccessTokenStore(),
);
