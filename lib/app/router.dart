import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/dashboard/presentation/more_page.dart';
import '../features/dashboard/presentation/student_dashboard_page.dart';
import '../features/dashboard/presentation/teacher_dashboard_page.dart';
import '../features/shared/presentation/feature_placeholder_page.dart';
import '../features/shared/presentation/student_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isPublic =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login';
      final isAuthenticated = session.status == SessionStatus.authenticated;

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) {
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
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
