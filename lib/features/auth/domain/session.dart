enum AppRole { student, teacher, admin }

enum SessionStatus { unauthenticated, authenticated }

class UserSession {
  const UserSession({
    required this.id,
    required this.firstName,
    required this.role,
  });

  final String id;
  final String firstName;
  final AppRole role;
}

class SessionState {
  const SessionState._({required this.status, this.user});

  const SessionState.unauthenticated()
    : this._(status: SessionStatus.unauthenticated);

  const SessionState.authenticated(UserSession user)
    : this._(status: SessionStatus.authenticated, user: user);

  final SessionStatus status;
  final UserSession? user;
}
