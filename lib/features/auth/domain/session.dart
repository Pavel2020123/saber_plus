enum AppRole { student, teacher, admin }

enum SessionStatus { restoring, unauthenticated, authenticated }

class UserSession {
  const UserSession({
    required this.id,
    required this.firstName,
    required this.role,
    this.email,
    this.xpTotal = 0,
    this.emailVerified = true,
    this.requiresEmailVerification = false,
    this.mustChangePassword = false,
    this.isDemo = false,
  });

  final String id;
  final String firstName;
  final AppRole role;
  final String? email;
  final int xpTotal;
  final bool emailVerified;
  final bool requiresEmailVerification;
  final bool mustChangePassword;
  final bool isDemo;

  UserSession copyWith({int? xpTotal}) => UserSession(
    id: id,
    firstName: firstName,
    role: role,
    email: email,
    xpTotal: xpTotal ?? this.xpTotal,
    emailVerified: emailVerified,
    requiresEmailVerification: requiresEmailVerification,
    mustChangePassword: mustChangePassword,
    isDemo: isDemo,
  );

  factory UserSession.fromBackendJson(Map<String, dynamic> json) => UserSession(
    id: json['id'] as String,
    firstName: json['nombre'] as String,
    email: json['correo'] as String?,
    xpTotal: json['xpTotal'] as int? ?? 0,
    role: _roleFromBackend(json['rol'] as String),
    emailVerified: json['correoVerificado'] as bool? ?? false,
    requiresEmailVerification:
        json['requiereVerificacionCorreo'] as bool? ?? false,
    mustChangePassword: json['debeCambiarContrasena'] as bool? ?? false,
  );

  static AppRole _roleFromBackend(String role) => switch (role.toUpperCase()) {
    'ESTUDIANTE' => AppRole.student,
    'PROFESOR' => AppRole.teacher,
    'ADMIN' => AppRole.admin,
    _ => throw FormatException('Rol de usuario no reconocido: $role'),
  };
}

class SessionState {
  const SessionState._({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorCode,
    this.errorMessage,
  });

  const SessionState.restoring() : this._(status: SessionStatus.restoring);

  const SessionState.unauthenticated({String? errorCode, String? errorMessage})
    : this._(
        status: SessionStatus.unauthenticated,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );

  const SessionState.authenticated(UserSession user)
    : this._(status: SessionStatus.authenticated, user: user);

  final SessionStatus status;
  final UserSession? user;
  final bool isLoading;
  final String? errorCode;
  final String? errorMessage;

  SessionState copyWith({
    SessionStatus? status,
    UserSession? user,
    bool? isLoading,
    String? errorCode,
    String? errorMessage,
    bool clearError = false,
  }) => SessionState._(
    status: status ?? this.status,
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
