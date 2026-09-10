import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/session_route_policy.dart';
import 'package:saber_plus/features/auth/domain/session.dart';

void main() {
  String? redirect(
    String location, {
    SessionStatus status = SessionStatus.authenticated,
    AppRole? role = AppRole.student,
    bool changePassword = false,
  }) => sessionRouteRedirect(
    location: location,
    status: status,
    role: role,
    mustChangePassword: changePassword,
  );

  for (final route in ['/teacher', '/teacher/groups', '/teacher/analytics']) {
    test('estudiante no abre $route', () {
      expect(redirect(route), '/student/home');
    });
    test('profesor conserva $route', () {
      expect(redirect(route, role: AppRole.teacher), isNull);
    });
  }
  for (final route in [
    '/student/home',
    '/student/study',
    '/student/diagnostic',
  ]) {
    test('profesor no abre $route', () {
      expect(redirect(route, role: AppRole.teacher), '/teacher');
    });
    test('estudiante conserva $route', () {
      expect(redirect(route), isNull);
    });
  }
  for (final route in ['/teacher/groups', '/student/study', '/login']) {
    test('restauración protege $route', () {
      expect(
        redirect(route, status: SessionStatus.restoring),
        '/session-loading',
      );
    });
    test('cambio inicial obligatorio precede a $route', () {
      expect(redirect(route, changePassword: true), '/change-initial-password');
    });
  }
  test('rutas públicas, cierre de sesión y carga no forman bucles', () {
    expect(redirect('/login', status: SessionStatus.unauthenticated), isNull);
    expect(
      redirect('/teacher/groups', status: SessionStatus.unauthenticated),
      '/login',
    );
    expect(
      redirect('/session-loading', status: SessionStatus.unauthenticated),
      '/welcome',
    );
    expect(
      redirect('/session-loading', status: SessionStatus.restoring),
      isNull,
    );
    expect(redirect('/change-initial-password', changePassword: true), isNull);
    expect(redirect('/change-initial-password'), '/student/home');
    expect(redirect('/login', role: AppRole.teacher), '/teacher');
  });
  test('no modifica el acceso administrativo existente', () {
    expect(redirect('/teacher/groups', role: AppRole.admin), isNull);
    expect(redirect('/student/home', role: AppRole.admin), isNull);
  });
}
