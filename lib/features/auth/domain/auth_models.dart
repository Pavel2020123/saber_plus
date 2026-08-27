import 'session.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}

class LoginResult {
  const LoginResult({required this.user, required this.tokens});

  final UserSession user;
  final AuthTokens tokens;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    user: UserSession.fromJson(json['user'] as Map<String, dynamic>),
    tokens: AuthTokens.fromJson(json),
  );
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.grade,
    required this.acceptedPolicyVersion,
    required this.guardianConsent,
    this.referralCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String grade;
  final String acceptedPolicyVersion;
  final bool guardianConsent;
  final String? referralCode;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'grade': grade,
    'acceptedPolicyVersion': acceptedPolicyVersion,
    'guardianConsent': guardianConsent,
    if (referralCode case final code? when code.isNotEmpty)
      'referralCode': code,
  };
}

class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.verificationRequired,
  });

  final String email;
  final bool verificationRequired;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) =>
      RegistrationResult(
        email: json['email'] as String,
        verificationRequired: json['verificationRequired'] as bool? ?? true,
      );
}
