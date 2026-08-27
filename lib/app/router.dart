import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/change_initial_password_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/auth/presentation/session_loading_page.dart';
import '../features/auth/presentation/verify_email_page.dart';
import '../features/auth/presentation/verify_pending_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/dashboard/presentation/more_page.dart';
import '../features/dashboard/presentation/student_dashboard_page.dart';
import '../features/dashboard/presentation/teacher_dashboard_page.dart';
import '../features/shared/presentation/feature_placeholder_page.dart';
import '../features/shared/presentation/student_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/session-loading',
    redirect: (context, state) {
      const publicRoutes = {
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
        '/verify-email',
        '/verify-pending',
      };
      final isPublic = publicRoutes.contains(state.matchedLocation);
      final isAuthenticated = session.status == SessionStatus.authenticated;

      if (session.status == SessionStatus.restoring) {
        return state.matchedLocation == '/session-loading'
            ? null
            : '/session-loading';
      }
      if (state.matchedLocation == '/session-loading') {
        if (!isAuthenticated) return '/welcome';
        return session.user?.role == AppRole.teacher
            ? '/teacher'
            : '/student/home';
      }

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) {
        return session.user?.role == AppRole.teacher
            ? '/teacher'
            : '/student/home';
      }
      if (isAuthenticated &&
          (session.user?.mustChangePassword ?? false) &&
          state.matchedLocation != '/change-initial-password') {
        return '/change-initial-password';
      }
      if (isAuthenticated &&
          !(session.user?.mustChangePassword ?? false) &&
          state.matchedLocation == '/change-initial-password') {
        return session.user?.role == AppRole.teacher
            ? '/teacher'
            : '/student/home';
      }
      if (isAuthenticated &&
          session.user?.role == AppRole.teacher &&
          state.matchedLocation.startsWith('/student')) {
        return '/teacher';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/session-loading',
        builder: (context, state) => const SessionLoadingPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      GoRoute(
        path: '/verify-pending',
        builder: (context, state) =>
            VerifyPendingPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) =>
            VerifyEmailPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      GoRoute(
        path: '/change-initial-password',
        builder: (context, state) => const ChangeInitialPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StudentDashboardPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/study',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FeaturePlaceholderPage(
                    title: 'Estudiar',
                    description:
                        'Aquí aparecerán las áreas, temas, lecciones y recursos descargables.',
                    icon: Icons.menu_book_rounded,
                    stage: 'Etapa 3 · Contenido académico',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/practice',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FeaturePlaceholderPage(
                    title: 'Practicar',
                    description:
                        'Prácticas por tema, preguntas aleatorias y simulacros protegidos.',
                    icon: Icons.quiz_rounded,
                    stage: 'Etapa 4 · Práctica y simulacros',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/progress',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FeaturePlaceholderPage(
                    title: 'Progreso',
                    description:
                        'Resultados, historial, cuaderno de errores y repaso inteligente.',
                    icon: Icons.insights_rounded,
                    stage: 'Etapa 5 · Progreso y repaso',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/more',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MorePage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardPage(),
      ),
    ],
  );
});
