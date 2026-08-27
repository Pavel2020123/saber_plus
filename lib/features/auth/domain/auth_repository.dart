import 'auth_models.dart';
import 'session.dart';

abstract interface class AuthRepository {
  Future<LoginResult> login({required String email, required String password});

  Future<RegistrationResult> register(RegistrationRequest request);

  Future<void> verifyEmail(String token);

  Future<void> resendVerification(String email);

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({required String token, required String password});

  Future<void> changeInitialPassword(String password);

  Future<UserSession> profile();
}
