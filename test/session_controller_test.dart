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

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> clear() async => token = null;
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
