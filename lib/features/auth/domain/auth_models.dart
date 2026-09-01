import 'session.dart';

enum RegistrationAccountType {
  student('Estudiante', 'ESTUDIANTE'),
  teacher('Profesor', 'PROFESOR');

  const RegistrationAccountType(this.label, this.backendValue);

  final String label;
  final String backendValue;
}

class AuthTokens {
  const AuthTokens({required this.accessToken});

  final String accessToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      AuthTokens(accessToken: json['accessToken'] as String);
}

class LoginResult {
  const LoginResult({required this.user, required this.tokens});

  final UserSession user;
  final AuthTokens tokens;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    user: UserSession.fromBackendJson(
      Map<String, dynamic>.from(json['usuario'] as Map),
    ),
    tokens: AuthTokens.fromJson(json),
  );
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.referralCode,
    this.accountType = RegistrationAccountType.student,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? referralCode;
  final RegistrationAccountType accountType;

  Map<String, dynamic> toBackendJson() => {
    'nombre': '$firstName $lastName'.trim(),
    'correo': email,
    'contrasena': password,
    'rol': accountType.backendValue,
    if (accountType == RegistrationAccountType.student)
      if (referralCode case final code? when code.isNotEmpty)
        'codigoReferido': code,
  };
}

class RegistrationResult {
  const RegistrationResult({required this.email, required this.userId});

  final String email;
  final String userId;

  factory RegistrationResult.fromJson(
    Map<String, dynamic> json, {
    required String email,
  }) => RegistrationResult(email: email, userId: json['usuarioId'] as String);
}
