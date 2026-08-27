import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/access_token_store.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/secure_session_store.dart';
import '../data/remote_auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/session.dart';

class SessionController extends Notifier<SessionState> {
  var _disposed = false;

  @override
  SessionState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(_restoreSession));
    return const SessionState.restoring();
  }

  Future<void> _restoreSession() async {
    final secureStore = ref.read(secureSessionStoreProvider);
    final refreshToken = await secureStore.readRefreshToken();
    if (_disposed) return;
    if (refreshToken == null || refreshToken.isEmpty) {
      state = const SessionState.unauthenticated();
      return;
    }

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .restore(refreshToken);
      await _persist(result);
      if (!_disposed) state = SessionState.authenticated(result.user);
    } on Object {
      await _clearTokens();
      if (!_disposed) state = const SessionState.unauthenticated();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim().toLowerCase(), password: password);
      await _persist(result);
      state = SessionState.authenticated(result.user);
      return true;
    } on ApiError catch (error) {
      _setError(error);
      return false;
    } on Object {
      _setError(
        const ApiError(
          code: 'invalid_response',
          message: 'El servidor respondió con un formato no compatible.',
        ),
      );
      return false;
    }
  }

  Future<RegistrationResult?> register(RegistrationRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(authRepositoryProvider).register(request);
      state = const SessionState.unauthenticated();
      return result;
    } on ApiError catch (error) {
      _setError(error);
      return null;
    } on Object {
      _setError(
        const ApiError(
          code: 'invalid_response',
          message: 'El servidor respondió con un formato no compatible.',
        ),
      );
      return null;
    }
  }

  Future<bool> requestPasswordReset(String email) => _runUnauthenticatedAction(
    () => ref
        .read(authRepositoryProvider)
        .requestPasswordReset(email.trim().toLowerCase()),
  );

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) => _runUnauthenticatedAction(
    () => ref
        .read(authRepositoryProvider)
        .resetPassword(token: token, password: password),
  );

  Future<bool> verifyEmail(String token) => _runUnauthenticatedAction(
    () => ref.read(authRepositoryProvider).verifyEmail(token),
  );

  Future<bool> resendVerification(String email) => _runUnauthenticatedAction(
    () => ref
        .read(authRepositoryProvider)
        .resendVerification(email.trim().toLowerCase()),
  );

  Future<bool> changeInitialPassword(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).changeInitialPassword(password);
      final refreshedUser = await ref.read(authRepositoryProvider).profile();
      state = SessionState.authenticated(refreshedUser);
      return true;
    } on ApiError catch (error) {
      _setError(error);
      return false;
    }
  }

  void enterDemo({AppRole role = AppRole.student}) {
    state = SessionState.authenticated(
      UserSession(
        id: 'demo-${role.name}',
        firstName: role == AppRole.teacher ? 'Profe Andrea' : 'Santiago',
        role: role,
        isDemo: true,
      ),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> signOut() async {
    final refreshToken = await ref
        .read(secureSessionStoreProvider)
        .readRefreshToken();
    final wasDemo = state.user?.isDemo ?? false;

    await _clearTokens();
    state = const SessionState.unauthenticated();

    if (!wasDemo && refreshToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } on Object {
        // El cierre local siempre prevalece aunque el servidor no responda.
      }
    }
  }

  Future<bool> _runUnauthenticatedAction(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = const SessionState.unauthenticated();
      return true;
    } on ApiError catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<void> _persist(LoginResult result) async {
    ref.read(accessTokenStoreProvider).set(result.tokens.accessToken);
    await ref
        .read(secureSessionStoreProvider)
        .saveRefreshToken(result.tokens.refreshToken);
  }

  Future<void> _clearTokens() async {
    ref.read(accessTokenStoreProvider).clear();
    await ref.read(secureSessionStoreProvider).clear();
  }

  void _setError(ApiError error) {
    state = state.copyWith(
      isLoading: false,
      errorCode: error.code,
      errorMessage: error.message,
    );
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
