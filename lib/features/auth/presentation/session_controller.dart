import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/access_token_store.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/secure_session_store.dart';
import '../data/remote_auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/session.dart';

enum SignInResult { authenticated, verificationRequired, failed }

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
    final accessToken = await secureStore.readAccessToken();
    if (_disposed) return;
    if (accessToken == null || accessToken.isEmpty) {
      state = const SessionState.unauthenticated();
      return;
    }

    try {
      ref.read(accessTokenStoreProvider).set(accessToken);
      final user = await ref.read(authRepositoryProvider).profile();
      if (user.requiresEmailVerification) {
        await _clearTokens();
        if (!_disposed) state = const SessionState.unauthenticated();
        return;
      }
      if (!_disposed) state = SessionState.authenticated(user);
    } on Object {
      await _clearTokens();
      if (!_disposed) state = const SessionState.unauthenticated();
    }
  }

  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim().toLowerCase(), password: password);
      await _persist(result);
      final user = await ref.read(authRepositoryProvider).profile();
      if (user.requiresEmailVerification) {
        await _clearTokens();
        state = const SessionState.unauthenticated();
        return SignInResult.verificationRequired;
      }
      state = SessionState.authenticated(user);
      return SignInResult.authenticated;
    } on ApiError catch (error) {
      await _clearTokens();
      _setError(error);
      return SignInResult.failed;
    } on Object {
      await _clearTokens();
      _setError(
        const ApiError(
          code: 'invalid_response',
          message: 'El servidor respondió con un formato no compatible.',
        ),
      );
      return SignInResult.failed;
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

  void enterDemo({AppRole role = AppRole.student}) {
    state = SessionState.authenticated(
      UserSession(
        id: 'demo-${role.name}',
        firstName: role == AppRole.teacher ? 'Profe Andrea' : 'Santiago',
        role: role,
        xpTotal: role == AppRole.student ? 1240 : 0,
        isDemo: true,
      ),
    );
  }

  Future<void> refreshProfile() async {
    final current = state.user;
    if (current == null || current.isDemo) return;
    try {
      final user = await ref.read(authRepositoryProvider).profile();
      if (!_disposed) state = SessionState.authenticated(user);
    } on Object {
      // La gamificación sigue disponible aunque falle esta actualización de XP.
    }
  }

  Future<void> registerEarnedXp(int earnedXp) async {
    final current = state.user;
    if (current == null) return;
    if (current.isDemo) {
      state = SessionState.authenticated(
        current.copyWith(xpTotal: current.xpTotal + earnedXp),
      );
      return;
    }
    await refreshProfile();
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> signOut() async {
    await _clearTokens();
    state = const SessionState.unauthenticated();
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

  Future<void> _persist(LoginResult result) async {
    ref.read(accessTokenStoreProvider).set(result.tokens.accessToken);
    await ref
        .read(secureSessionStoreProvider)
        .saveAccessToken(result.tokens.accessToken);
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
