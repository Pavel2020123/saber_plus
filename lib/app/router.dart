import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sync/sync_queue_page.dart';
import '../core/preferences/preferences_page.dart';
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
import '../features/announcements/presentation/announcements_page.dart';
import '../features/battles/presentation/async_battles_page.dart';
import '../features/battles/presentation/battle_detail_page.dart';
import '../features/battles/presentation/blocked_rivals_page.dart';
import '../features/academic/domain/academic_models.dart';
import '../features/academic/presentation/diagnostic_overview_page.dart';
import '../features/dashboard/presentation/more_page.dart';
import '../features/dashboard/presentation/student_dashboard_page.dart';
import '../features/dashboard/presentation/teacher_dashboard_page.dart';
import '../features/institutions/presentation/institution_administration_page.dart';
import '../features/institutions/presentation/institution_groups_page.dart';
import '../features/institutions/presentation/student_group_join_page.dart';
import '../features/institutions/presentation/teacher_basic_analytics_page.dart';
import '../features/institutions/presentation/teacher_detailed_analytics_page.dart';
import '../features/difficult_questions/presentation/difficult_questions_page.dart';
import '../features/gamification/presentation/gamification_page.dart';
import '../features/games/trivia_rush/domain/trivia_rush_models.dart';
import '../features/games/trivia_rush/presentation/trivia_rush_page.dart';
import '../features/games/trivia_rush/presentation/trivia_rush_setup_page.dart';
import '../features/games/memory_match/domain/memory_match_models.dart';
import '../features/games/memory_match/presentation/memory_match_page.dart';
import '../features/games/memory_match/presentation/memory_match_setup_page.dart';
import '../features/games/ghost_duel/domain/ghost_duel_models.dart';
import '../features/games/ghost_duel/presentation/ghost_duel_setup_page.dart';
import '../features/games/tug_of_war/domain/tug_of_war_models.dart';
import '../features/games/tug_of_war/presentation/tug_of_war_page.dart';
import '../features/games/tug_of_war/presentation/tug_online_page.dart';
import '../features/games/tug_of_war/presentation/tug_of_war_setup_page.dart';
import '../features/historical_simulations/presentation/historical_simulation_detail_page.dart';
import '../features/historical_simulations/presentation/historical_simulations_page.dart';
import '../features/favorites/presentation/favorites_page.dart';
import '../features/flashcards/domain/flashcard_models.dart';
import '../features/flashcards/presentation/flashcard_session_page.dart';
import '../features/flashcards/presentation/flashcards_page.dart';
import '../features/library/presentation/reference_library_page.dart';
import '../features/practice/domain/practice_models.dart';
import '../features/practice/presentation/practice_history_page.dart';
import '../features/practice/presentation/practice_hub_page.dart';
import '../features/practice/presentation/daily_mistakes_page.dart';
import '../features/practice/presentation/official_simulation_page.dart';
import '../features/practice/presentation/random_practice_setup_page.dart';
import '../features/practice/presentation/practice_session_page.dart';
import '../features/practice/presentation/simulation_setup_page.dart';
import '../features/practice/presentation/simulation_comparison_page.dart';
import '../features/practice/presentation/time_trial_setup_page.dart';
import '../features/progress/presentation/adaptive_review_page.dart';
import '../features/progress/presentation/progress_page.dart';
import '../features/profile/presentation/academic_profile_page.dart';
import '../features/profile/presentation/academic_activity_report_page.dart';
import '../features/profile/presentation/score_projection_page.dart';
import '../features/profile/presentation/career_orientation_page.dart';
import '../features/profile/presentation/official_opportunities_page.dart';
import '../features/profile/presentation/national_score_comparison_page.dart';
import '../features/ranking/presentation/ranking_page.dart';
import '../features/referrals/presentation/referrals_page.dart';
import '../features/search/presentation/academic_search_page.dart';
import '../features/score_calculator/presentation/score_calculator_page.dart';
import '../features/shared/presentation/student_shell.dart';
import '../features/study/presentation/study_area_page.dart';
import '../features/study/presentation/study_areas_page.dart';
import '../features/study/presentation/study_lesson_page.dart';
import '../features/study/presentation/offline_downloads_page.dart';
import '../features/study/presentation/syllabus_countdown_page.dart';
import '../features/study_time/presentation/study_time_page.dart';
import '../features/support/presentation/support_page.dart';
import 'page_transitions.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(
    sessionControllerProvider.select(
      (state) => (
        status: state.status,
        role: state.user?.role,
        mustChangePassword: state.user?.mustChangePassword ?? false,
      ),
    ),
  );

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
        return session.role == AppRole.teacher ? '/teacher' : '/student/home';
      }

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) {
        return session.role == AppRole.teacher ? '/teacher' : '/student/home';
      }
      if (isAuthenticated &&
          session.mustChangePassword &&
          state.matchedLocation != '/change-initial-password') {
        return '/change-initial-password';
      }
      if (isAuthenticated &&
          !session.mustChangePassword &&
          state.matchedLocation == '/change-initial-password') {
        return session.role == AppRole.teacher ? '/teacher' : '/student/home';
      }
      if (isAuthenticated &&
          session.role == AppRole.teacher &&
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
      _animatedRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      _animatedRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      _animatedRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      _animatedRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      _animatedRoute(
        path: '/verify-pending',
        builder: (context, state) =>
            VerifyPendingPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      _animatedRoute(
        path: '/verify-email',
        builder: (context, state) =>
            VerifyEmailPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      _animatedRoute(
        path: '/change-initial-password',
        builder: (context, state) => const ChangeInitialPasswordPage(),
      ),
      _animatedRoute(
        path: '/student/diagnostic',
        builder: (context, state) => const DiagnosticOverviewPage(),
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StudyAreasPage()),
                routes: [
                  _animatedRoute(
                    path: 'search',
                    builder: (context, state) => const AcademicSearchPage(),
                  ),
                  _animatedRoute(
                    path: 'downloads',
                    builder: (context, state) => const OfflineDownloadsPage(),
                  ),
                  _animatedRoute(
                    path: 'countdown',
                    builder: (context, state) => const SyllabusCountdownPage(),
                  ),
                  _animatedRoute(
                    path: ':area',
                    builder: (context, state) => StudyAreaPage(
                      area: AcademicArea.fromSlug(
                        state.pathParameters['area']!,
                      ),
                    ),
                    routes: [
                      _animatedRoute(
                        path: ':themeId/:subtopicId',
                        builder: (context, state) => StudyLessonPage(
                          area: AcademicArea.fromSlug(
                            state.pathParameters['area']!,
                          ),
                          themeId: state.pathParameters['themeId']!,
                          subtopicId: state.pathParameters['subtopicId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/practice',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PracticeHubPage()),
                routes: [
                  _animatedRoute(
                    path: 'battles',
                    builder: (context, state) => const AsyncBattlesPage(),
                    routes: [
                      _animatedRoute(
                        path: 'blocked',
                        builder: (context, state) => const BlockedRivalsPage(),
                      ),
                      _animatedRoute(
                        path: ':battleId',
                        builder: (context, state) => BattleDetailPage(
                          battleId: state.pathParameters['battleId']!,
                        ),
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'trivia-rush',
                    builder: (context, state) => const TriviaRushSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'play',
                        builder: (context, state) {
                          final config = TriviaRushConfig.tryFromUri(state.uri);
                          if (config == null) {
                            return const TriviaRushSetupPage();
                          }
                          return TriviaRushPage(config: config);
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'memory-match',
                    builder: (context, state) => const MemoryMatchSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'play',
                        builder: (context, state) {
                          final config = MemoryMatchConfig.tryFromUri(
                            state.uri,
                          );
                          if (config == null) {
                            return const MemoryMatchSetupPage();
                          }
                          return MemoryMatchPage(config: config);
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'ghost-duel',
                    builder: (context, state) => const GhostDuelSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'play',
                        builder: (context, state) {
                          final config = GhostDuelConfig.tryFromUri(state.uri);
                          if (config == null) {
                            return const GhostDuelSetupPage();
                          }
                          return TriviaRushPage(
                            config: config.triviaConfig,
                            ghostMode: true,
                          );
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'tug-of-war',
                    builder: (context, state) => const TugOfWarSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'online',
                        builder: (context, state) => TugOnlinePage(
                          config: TugOnlineConfig.tryFromUri(state.uri),
                        ),
                      ),
                      _animatedRoute(
                        path: 'play',
                        builder: (context, state) {
                          final config = TugOfWarConfig.tryFromUri(state.uri);
                          if (config == null) {
                            return const TugOfWarSetupPage();
                          }
                          return TugOfWarPage(config: config);
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'official',
                    builder: (context, state) => const OfficialSimulationPage(),
                    routes: [
                      _animatedRoute(
                        path: ':block',
                        builder: (context, state) {
                          final block = OfficialSimulationBlock.tryFromSlug(
                            state.pathParameters['block'] ?? '',
                          );
                          if (block == null) {
                            return const OfficialSimulationPage();
                          }
                          return PracticeSessionPage.official(
                            officialBlock: block,
                          );
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'past',
                    builder: (context, state) =>
                        const HistoricalSimulationsPage(),
                    routes: [
                      _animatedRoute(
                        path: ':editionId',
                        builder: (context, state) =>
                            HistoricalSimulationDetailPage(
                              editionId: state.pathParameters['editionId']!,
                            ),
                        routes: [
                          _animatedRoute(
                            path: ':block',
                            builder: (context, state) {
                              final block = OfficialSimulationBlock.tryFromSlug(
                                state.pathParameters['block'] ?? '',
                              );
                              if (block == null) {
                                return HistoricalSimulationDetailPage(
                                  editionId: state.pathParameters['editionId']!,
                                );
                              }
                              return PracticeSessionPage.historical(
                                historicalEditionId:
                                    state.pathParameters['editionId']!,
                                historicalBlock: block,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'simulation',
                    builder: (context, state) => const SimulationSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: ':area',
                        builder: (context, state) =>
                            PracticeSessionPage.simulation(
                              area: AcademicArea.fromSlug(
                                state.pathParameters['area']!,
                              ),
                            ),
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'time-trial',
                    builder: (context, state) => const TimeTrialSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'session',
                        builder: (context, state) {
                          final config = TimeTrialConfig.tryFromUri(state.uri);
                          if (config == null) {
                            return const TimeTrialSetupPage();
                          }
                          return PracticeSessionPage.timeTrial(
                            timeTrialConfig: config,
                          );
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'history',
                    builder: (context, state) => const PracticeHistoryPage(),
                  ),
                  _animatedRoute(
                    path: 'comparison',
                    builder: (context, state) =>
                        const SimulationComparisonPage(),
                  ),
                  _animatedRoute(
                    path: 'daily-review',
                    builder: (context, state) => const DailyMistakesPage(),
                  ),
                  _animatedRoute(
                    path: 'random',
                    builder: (context, state) =>
                        const RandomPracticeSetupPage(),
                    routes: [
                      _animatedRoute(
                        path: 'session',
                        builder: (context, state) {
                          final config = RandomPracticeConfig.tryFromUri(
                            state.uri,
                          );
                          if (config == null) {
                            return const RandomPracticeSetupPage();
                          }
                          return PracticeSessionPage.random(
                            randomConfig: config,
                          );
                        },
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'subtopic/:area/:subtopicId',
                    builder: (context, state) => PracticeSessionPage(
                      area: AcademicArea.fromSlug(
                        state.pathParameters['area']!,
                      ),
                      subtopicId: state.pathParameters['subtopicId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/progress',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProgressPage()),
                routes: [
                  _animatedRoute(
                    path: 'library',
                    builder: (context, state) => const ReferenceLibraryPage(),
                  ),
                  _animatedRoute(
                    path: 'flashcards',
                    builder: (context, state) => const FlashcardsPage(),
                    routes: [
                      _animatedRoute(
                        path: 'session',
                        builder: (context, state) => FlashcardSessionPage(
                          config: FlashcardSessionConfig.fromUri(state.uri),
                        ),
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'adaptive',
                    builder: (context, state) => const AdaptiveReviewPage(),
                    routes: [
                      _animatedRoute(
                        path: 'session',
                        builder: (context, state) {
                          final value = int.tryParse(
                            state.uri.queryParameters['cantidad'] ?? '',
                          );
                          final count =
                              value != null && value >= 5 && value <= 30
                              ? value
                              : 15;
                          return PracticeSessionPage.adaptive(
                            questionCount: count,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/more',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MorePage()),
                routes: [
                  _animatedRoute(
                    path: 'profile',
                    builder: (context, state) => const AcademicProfilePage(),
                    routes: [
                      _animatedRoute(
                        path: 'activity',
                        builder: (context, state) =>
                            const AcademicActivityReportPage(),
                      ),
                      _animatedRoute(
                        path: 'projection',
                        builder: (context, state) =>
                            const ScoreProjectionPage(),
                      ),
                      _animatedRoute(
                        path: 'orientation',
                        builder: (context, state) =>
                            const CareerOrientationPage(),
                      ),
                      _animatedRoute(
                        path: 'opportunities',
                        builder: (context, state) =>
                            const OfficialOpportunitiesPage(),
                      ),
                      _animatedRoute(
                        path: 'national-comparison',
                        builder: (context, state) =>
                            const NationalScoreComparisonPage(),
                      ),
                    ],
                  ),
                  _animatedRoute(
                    path: 'institution',
                    builder: (context, state) => const StudentGroupJoinPage(),
                  ),
                  _animatedRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesPage(),
                  ),
                  _animatedRoute(
                    path: 'difficult-questions',
                    builder: (context, state) => const DifficultQuestionsPage(),
                  ),
                  _animatedRoute(
                    path: 'gamification',
                    builder: (context, state) => const GamificationPage(),
                  ),
                  _animatedRoute(
                    path: 'study-time',
                    builder: (context, state) => const StudyTimePage(),
                  ),
                  _animatedRoute(
                    path: 'ranking',
                    builder: (context, state) => const RankingPage(),
                  ),
                  _animatedRoute(
                    path: 'announcements',
                    builder: (context, state) => const AnnouncementsPage(),
                  ),
                  _animatedRoute(
                    path: 'score-calculator',
                    builder: (context, state) => const ScoreCalculatorPage(),
                  ),
                  _animatedRoute(
                    path: 'referrals',
                    builder: (context, state) => const ReferralsPage(),
                  ),
                  _animatedRoute(
                    path: 'support',
                    builder: (context, state) => const SupportPage(),
                  ),
                  _animatedRoute(
                    path: 'preferences',
                    builder: (context, state) => const PreferencesPage(),
                  ),
                  _animatedRoute(
                    path: 'sync',
                    builder: (context, state) => const SyncQueuePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardPage(),
        routes: [
          _animatedRoute(
            path: 'administration',
            builder: (context, state) => const InstitutionAdministrationPage(),
          ),
          _animatedRoute(
            path: 'groups',
            builder: (context, state) => const InstitutionGroupsPage(),
          ),
          _animatedRoute(
            path: 'analytics',
            builder: (context, state) => const TeacherBasicAnalyticsPage(),
          ),
          _animatedRoute(
            path: 'detailed-analytics',
            builder: (context, state) => const TeacherDetailedAnalyticsPage(),
          ),
        ],
      ),
    ],
  );
});

GoRoute _animatedRoute({
  required String path,
  required GoRouterWidgetBuilder builder,
  List<RouteBase> routes = const <RouteBase>[],
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) =>
      saberPage(key: state.pageKey, child: builder(context, state)),
  routes: routes,
);
