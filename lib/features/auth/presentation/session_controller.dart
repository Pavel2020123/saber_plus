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
  var _generation = 0;
  Future<void> _storageWrites = Future<void>.value();

  @override
  SessionState build() {
    _disposed = false;
    final generation = ++_generation;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    unawaited(Future<void>.microtask(() => _restoreSession(generation)));
    return const SessionState.restoring();
  }

  Future<void> _restoreSession(int generation) async {
    if (!_isCurrent(generation)) return;
    try {
      final accessToken = await ref
          .read(secureSessionStoreProvider)
          .readAccessToken();
      if (!_isCurrent(generation)) return;
      if (accessToken == null || accessToken.isEmpty) {
        state = const SessionState.unauthenticated();
        return;
      }
      ref.read(accessTokenStoreProvider).set(accessToken);
      final user = await ref.read(authRepositoryProvider).profile();
      if (!_isCurrent(generation)) return;
      if (user.requiresEmailVerification) {
        await _clearTokens();
        if (_isCurrent(generation)) {
          state = const SessionState.unauthenticated();
        }
        return;
      }
      state = SessionState.authenticated(user);
    } on Object {
      if (!_isCurrent(generation)) return;
      await _clearTokens();
      if (_isCurrent(generation)) state = const SessionState.unauthenticated();
    }
  }

  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    if (_disposed) return SignInResult.failed;
    final generation = ++_generation;
    state = const SessionState.unauthenticated().copyWith(isLoading: true);
    try {
      await _clearTokens();
      if (!_isCurrent(generation)) return SignInResult.failed;
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim().toLowerCase(), password: password);
      if (!_isCurrent(generation)) return SignInResult.failed;
      if (result.tokens.accessToken.trim().isEmpty) {
        throw const FormatException('El token de acceso está vacío.');
      }
      await _persist(result);
      if (!_isCurrent(generation)) return SignInResult.failed;
      final user = await ref.read(authRepositoryProvider).profile();
      if (!_isCurrent(generation)) return SignInResult.failed;
      if (user.id != result.user.id) {
        throw const FormatException('El perfil no corresponde a esta sesión.');
      }
      if (user.requiresEmailVerification) {
        await _clearTokens();
        if (!_isCurrent(generation)) return SignInResult.failed;
        state = const SessionState.unauthenticated();
        return SignInResult.verificationRequired;
      }
      state = SessionState.authenticated(user);
      return SignInResult.authenticated;
    } on ApiError catch (error) {
      if (!_isCurrent(generation)) return SignInResult.failed;
      await _clearTokens();
      if (_isCurrent(generation)) _setError(error);
      return SignInResult.failed;
    } on Object {
      if (!_isCurrent(generation)) return SignInResult.failed;
      await _clearTokens();
      if (!_isCurrent(generation)) return SignInResult.failed;
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
    if (_disposed) return null;
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(authRepositoryProvider).register(request);
      if (!_isCurrent(generation)) return null;
      state = const SessionState.unauthenticated();
      return result;
    } on ApiError catch (error) {
      if (!_isCurrent(generation)) return null;
      _setError(error);
      return null;
    } on Object {
      if (!_isCurrent(generation)) return null;
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
    if (_disposed) return false;
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).changeInitialPassword(password);
      if (!_isCurrent(generation)) return false;
      final refreshedUser = await ref.read(authRepositoryProvider).profile();
      if (!_isCurrent(generation)) return false;
      state = SessionState.authenticated(refreshedUser);
      return true;
    } on ApiError catch (error) {
      if (!_isCurrent(generation)) return false;
      _setError(error);
      return false;
    } on Object {
      if (!_isCurrent(generation)) return false;
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
    if (_disposed) return;
    _generation++;
    // Invalida inmediatamente el token real, incluso si su borrado nativo tarda.
    unawaited(_clearTokens());
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
    if (_disposed) return;
    final generation = _generation;
    final current = state.user;
    if (current == null || current.isDemo) return;
    try {
      final user = await ref.read(authRepositoryProvider).profile();
      if (_isCurrent(generation) &&
          state.user?.id == current.id &&
          user.id == current.id) {
        state = SessionState.authenticated(user);
      }
    } on Object {
      // La gamificación sigue disponible aunque falle esta actualización de XP.
    }
  }

  Future<void> registerEarnedXp(int earnedXp) async {
    if (_disposed) return;
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

  void clearError() {
    if (!_disposed) state = state.copyWith(clearError: true);
  }

  Future<void> signOut() async {
    if (_disposed) return;
    final generation = ++_generation;
    final clearing = _clearTokens();
    // No se mantiene la pantalla autenticada mientras responde Keychain/Keystore.
    state = const SessionState.unauthenticated();
    if (!await clearing && _isCurrent(generation)) {
      state = const SessionState.unauthenticated(
        errorCode: 'session_storage_error',
        errorMessage:
            'Se cerró la sesión, pero no se pudo borrar la credencial guardada. Intenta cerrar sesión nuevamente antes de compartir este dispositivo.',
      );
    }
  }

  Future<void> invalidateFromOtherDevice({required String message}) async {
    if (_disposed) return;
    if (state.status != SessionStatus.authenticated) return;
    _generation++;
    final clearing = _clearTokens();
    state = SessionState.unauthenticated(
      errorCode: 'device_session_conflict',
      errorMessage: message,
    );
    await clearing;
  }

  Future<bool> _runUnauthenticatedAction(Future<void> Function() action) async {
    if (_disposed) return false;
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      if (!_isCurrent(generation)) return false;
      state = const SessionState.unauthenticated();
      return true;
    } on ApiError catch (error) {
      if (!_isCurrent(generation)) return false;
      _setError(error);
      return false;
    } on Object {
      if (!_isCurrent(generation)) return false;
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
    final store = ref.read(secureSessionStoreProvider);
    await _enqueueStorage(
      () => store.saveAccessToken(result.tokens.accessToken),
    );
  }

  Future<bool> _clearTokens() async {
    ref.read(accessTokenStoreProvider).clear();
    final store = ref.read(secureSessionStoreProvider);
    try {
      await _enqueueStorage(store.clear);
      return true;
    } on Object {
      return false;
    }
  }

  // Ordena las escrituras: un login que termina tarde nunca puede persistir su
  // token después del borrado solicitado por logout o por entrar a demostración.
  Future<void> _enqueueStorage(Future<void> Function() action) {
    final pending = _storageWrites.then((_) => action());
    _storageWrites = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return pending;
  }

  bool _isCurrent(int generation) => !_disposed && _generation == generation;

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
