import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessTokenStore {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void set(String token) => _accessToken = token;

  void clear() => _accessToken = null;
}

final accessTokenStoreProvider = Provider<AccessTokenStore>(
  (ref) => AccessTokenStore(),
);
