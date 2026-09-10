import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/storage/secure_session_store.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/auth/domain/auth_models.dart';
import 'package:saber_plus/features/auth/domain/auth_repository.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';

void main() {
  group('frontera de sesión y respuestas tardías', () {
    late ProviderContainer container;
    late _ControlledAuthRepository repository;
    late _MemorySecureSessionStore secureStore;
    late AccessTokenStore tokenStore;

    setUp(() {
      repository = _ControlledAuthRepository();
      secureStore = _MemorySecureSessionStore();
      tokenStore = AccessTokenStore();
      container = ProviderContainer(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(secureStore),
          accessTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });
    tearDown(() => container.dispose());

    Future<SessionController> controller() async {
      container.read(sessionControllerProvider);
      await Future<void>.delayed(Duration.zero);
      return container.read(sessionControllerProvider.notifier);
    }

    test('un login pendiente no vuelve a entrar después de logout', () async {
      final session = await controller();
      final login = session.signIn(email: 'a@example.com', password: 'unused');
      await Future<void>.delayed(Duration.zero);
      await session.signOut();
      repository.loginResult.complete(_ControlledAuthRepository.result);
      expect(await login, SignInResult.failed);
      expect(repository.profileCalls, 0);
      expect(container.read(sessionControllerProvider).user, isNull);
      expect(tokenStore.accessToken, isNull);
      expect(secureStore.token, isNull);
    });

    test('un perfil de restauración no reemplaza la demostración', () async {
      secureStore.token = 'saved-token';
      final session = await controller();
      expect(repository.profileCalls, 1);
      session.enterDemo();
      repository.profileResult.complete(_ControlledAuthRepository.user);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionControllerProvider).user?.isDemo, isTrue);
      expect(tokenStore.accessToken, isNull);
      expect(secureStore.token, isNull);
    });

    test('un refresh pendiente no reabre una cuenta cerrada', () async {
      secureStore.token = 'saved-token';
      final session = await controller();
      repository.profileResult.complete(_ControlledAuthRepository.user);
      await Future<void>.delayed(Duration.zero);
      repository.profileResult = Completer<UserSession>();
      final refresh = session.refreshProfile();
      await session.signOut();
      repository.profileResult.complete(_ControlledAuthRepository.user);
      await refresh;
      expect(container.read(sessionControllerProvider).user, isNull);
      expect(tokenStore.accessToken, isNull);
    });

    test(
      'ordena el borrado después de una persistencia nativa en curso',
      () async {
        final session = await controller();
        secureStore.writeGate = Completer<void>();
        final login = session.signIn(
          email: 'a@example.com',
          password: 'unused',
        );
        repository.loginResult.complete(_ControlledAuthRepository.result);
        await Future<void>.delayed(Duration.zero);
        expect(tokenStore.accessToken, 'login-token');
        final logout = session.signOut();
        expect(container.read(sessionControllerProvider).user, isNull);
        expect(tokenStore.accessToken, isNull);
        secureStore.writeGate!.complete();
        await logout;
        expect(await login, SignInResult.failed);
        expect(secureStore.token, isNull);
        expect(repository.profileCalls, 0);
      },
    );

    test(
      'ignora el error tardío de un intento anterior al nuevo login',
      () async {
        final session = await controller();
        final firstCompletion = repository.loginResult;
        final first = session.signIn(
          email: 'a@example.com',
          password: 'unused',
        );
        await Future<void>.delayed(Duration.zero);
        repository.loginResult = Completer<LoginResult>();
        final second = session.signIn(
          email: 'b@example.com',
          password: 'unused',
        );
        repository.loginResult.complete(_ControlledAuthRepository.result);
        repository.profileResult.complete(_ControlledAuthRepository.user);
        expect(await second, SignInResult.authenticated);
        firstCompletion.completeError(StateError('late login failure'));
        expect(await first, SignInResult.failed);
        expect(container.read(sessionControllerProvider).user?.id, 'user-1');
        expect(tokenStore.accessToken, 'login-token');
        expect(secureStore.token, 'login-token');
      },
    );

    test(
      'un fallo del almacén al restaurar termina fuera de la cuenta',
      () async {
        secureStore.readError = StateError('secure storage unavailable');
        await controller();
        expect(
          container.read(sessionControllerProvider).status,
          SessionStatus.unauthenticated,
        );
        expect(tokenStore.accessToken, isNull);
      },
    );

    test(
      'un resultado de login tras dispose no persiste credenciales',
      () async {
        final session = await controller();
        final login = session.signIn(
          email: 'a@example.com',
          password: 'unused',
        );
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        container = ProviderContainer();
        repository.loginResult.complete(_ControlledAuthRepository.result);
        expect(await login, SignInResult.failed);
        expect(secureStore.token, isNull);
        expect(tokenStore.accessToken, isNull);
      },
    );
  });

  test('acumula el XP ganado en una sesión demostrativa', () async {
    final secureStore = _MemorySecureSessionStore();
    final container = ProviderContainer(
      overrides: [
        secureSessionStoreProvider.overrideWithValue(secureStore),
        accessTokenStoreProvider.overrideWithValue(AccessTokenStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(sessionControllerProvider.notifier);
    controller.enterDemo();
    await controller.registerEarnedXp(60);

    expect(container.read(sessionControllerProvider).user?.xpTotal, 1300);
  });

  test(
    'cierra localmente una sesión reemplazada en otro dispositivo',
    () async {
      final secureStore = _MemorySecureSessionStore();
      final tokenStore = AccessTokenStore();
      final container = ProviderContainer(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(secureStore),
          accessTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(sessionControllerProvider.notifier);
      secureStore.token = 'jwt';
      tokenStore.set('jwt');
      controller.enterDemo();

      await controller.invalidateFromOtherDevice(
        message: 'Tu sesión se abrió en otro dispositivo.',
      );

      final session = container.read(sessionControllerProvider);
      expect(session.status, SessionStatus.unauthenticated);
      expect(session.errorCode, 'device_session_conflict');
      expect(session.errorMessage, contains('otro dispositivo'));
      expect(tokenStore.accessToken, isNull);
      expect(await secureStore.readAccessToken(), isNull);
    },
  );

  test(
    'no conserva sesión cuando el perfil exige verificar el correo',
    () async {
      final secureStore = _MemorySecureSessionStore();
      final tokenStore = AccessTokenStore();
      final container = ProviderContainer(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(secureStore),
          accessTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(_UnverifiedAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final result = await container
          .read(sessionControllerProvider.notifier)
          .signIn(email: 'ana@example.com', password: 'Password1');

      expect(result, SignInResult.verificationRequired);
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.unauthenticated,
      );
      expect(tokenStore.accessToken, isNull);
      expect(await secureStore.readAccessToken(), isNull);
    },
  );
}

class _MemorySecureSessionStore extends SecureSessionStore {
  _MemorySecureSessionStore() : super(const FlutterSecureStorage());

  String? token;
  Completer<void>? writeGate;
  Object? readError;

  @override
  Future<void> saveAccessToken(String token) async {
    await writeGate?.future;
    this.token = token;
  }

  @override
  Future<String?> readAccessToken() async {
    if (readError case final error?) throw error;
    return token;
  }

  @override
  Future<void> clear() async => token = null;
}

class _ControlledAuthRepository extends _UnverifiedAuthRepository {
  static const user = UserSession(
    id: 'user-1',
    firstName: 'Ana',
    role: AppRole.student,
  );
  static const result = LoginResult(
    user: user,
    tokens: AuthTokens(accessToken: 'login-token'),
  );
  var loginResult = Completer<LoginResult>();
  var profileResult = Completer<UserSession>();
  var profileCalls = 0;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) => loginResult.future;

  @override
  Future<UserSession> profile() {
    profileCalls++;
    return profileResult.future;
  }
}

class _UnverifiedAuthRepository implements AuthRepository {
  static const user = UserSession(
    id: 'user-1',
    firstName: 'Ana Pérez',
    role: AppRole.student,
    email: 'ana@example.com',
    emailVerified: false,
    requiresEmailVerification: true,
  );

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async => const LoginResult(
    user: user,
    tokens: AuthTokens(accessToken: 'jwt'),
  );

  @override
  Future<UserSession> profile() async => user;

  @override
  Future<RegistrationResult> register(RegistrationRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> verifyEmail(String token) => throw UnimplementedError();

  @override
  Future<void> resendVerification(String email) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> changeInitialPassword(String password) =>
      throw UnimplementedError();
}
