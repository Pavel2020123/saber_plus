enum AppRole { student, teacher, admin }

enum SessionStatus { restoring, unauthenticated, authenticated }

class UserSession {
  const UserSession({
    required this.id,
    required this.firstName,
    required this.role,
    this.email,
    this.emailVerified = true,
    this.mustChangePassword = false,
    this.isDemo = false,
  });

  final String id;
  final String firstName;
  final AppRole role;
  final String? email;
  final bool emailVerified;
  final bool mustChangePassword;
  final bool isDemo;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    email: json['email'] as String?,
    role: AppRole.values.firstWhere(
      (role) => role.name == (json['role'] as String).toLowerCase(),
    ),
    emailVerified: json['emailVerified'] as bool? ?? false,
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  );
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

  const SessionState.unauthenticated()
    : this._(status: SessionStatus.unauthenticated);

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
