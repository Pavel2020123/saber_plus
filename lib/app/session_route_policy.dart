import '../features/auth/domain/session.dart';

/// Navigation policy only; API authorization must still be enforced server-side.
/// Kept independent from widgets so incoming links and nested routes share it.
String? sessionRouteRedirect({
  required String location,
  required SessionStatus status,
  required AppRole? role,
  required bool mustChangePassword,
}) {
  const publicRoutes = {
    '/welcome',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-email',
    '/verify-pending',
  };
  if (status == SessionStatus.restoring) {
    return location == '/session-loading' ? null : '/session-loading';
  }
  if (status != SessionStatus.authenticated) {
    if (location == '/session-loading') return '/welcome';
    return publicRoutes.contains(location) ? null : '/login';
  }
  if (mustChangePassword) {
    return location == '/change-initial-password'
        ? null
        : '/change-initial-password';
  }

  final home = role == AppRole.teacher ? '/teacher' : '/student/home';
  if (location == '/session-loading' ||
      location == '/change-initial-password' ||
      publicRoutes.contains(location)) {
    return home;
  }
  if (role == AppRole.teacher && _isWithin(location, '/student')) {
    return '/teacher';
  }
  if (role == AppRole.student && _isWithin(location, '/teacher')) {
    return '/student/home';
  }
  return null;
}

bool _isWithin(String location, String root) =>
    location == root || location.startsWith('$root/');
