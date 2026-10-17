import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/student_request_notice_store.dart';
import 'package:saber_plus/features/institutions/data/demo_institution_group_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_group_models.dart';
import 'package:saber_plus/features/institutions/domain/student_institution_request.dart';
import 'package:saber_plus/features/institutions/presentation/institution_group_providers.dart';
import 'package:saber_plus/features/institutions/presentation/student_group_join_page.dart';
import 'package:saber_plus/features/institutions/presentation/student_institution_request_providers.dart';
import 'package:saber_plus/features/institutions/presentation/student_request_shortcut.dart';
import 'student_institution_requests_test.dart' as fixtures;

class NoticePreferences extends Fake implements SharedPreferencesAsync {
  NoticePreferences({this.failRead = false, this.failWrite = false});
  final values = <String, String>{};
  final bool failRead, failWrite;
  @override
  Future<String?> getString(String key) async {
    if (failRead) throw Exception('unavailable');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrite) throw Exception('unavailable');
    values[key] = value;
  }
}

class ShortcutSession extends fixtures.TestRequestSession {
  ShortcutSession(super.initial);
  int refreshes = 0;
  @override
  Future<void> refreshProfile() async {
    refreshes++;
  }
}

class LinkedNoGroups extends DemoInstitutionGroupRepository {
  @override
  Future<StudentInstitutionGroups> loadStudentGroups() async =>
      const StudentInstitutionGroups(
        groups: [],
        institutionId: fixtures.institutionId,
      );
}

Future<void> mount(
  WidgetTester tester,
  fixtures.RequestFake repo, {
  UserSession user = fixtures.student,
  NoticePreferences? preferences,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => ShortcutSession(user)),
        studentInstitutionRequestRepositoryProvider.overrideWithValue(repo),
        studentRequestNoticeStoreProvider.overrideWithValue(
          LocalStudentRequestNoticeStore(preferences ?? NoticePreferences()),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: StudentRequestShortcut())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('matriz contextual: solo pendiente y rechazo sin consultar', () {
    expect(const StudentRequestMenuState().visible, false);
    for (final state in StudentRequestStatus.values) {
      expect(
        StudentRequestMenuState(
          latest: fixtures.row(state: state.value),
        ).visible,
        state == StudentRequestStatus.pending ||
            state == StudentRequestStatus.rejected,
      );
    }
    expect(
      StudentRequestMenuState(
        latest: fixtures.row(state: 'RECHAZADA'),
        rejectionRead: true,
      ).visible,
      false,
    );
  });
  test(
    'lectura persiste por cuenta, UUID y revisión sin guardar mensaje',
    () async {
      final preferences = NoticePreferences();
      final rejected = fixtures.row(state: 'RECHAZADA', revision: 1);
      final first = LocalStudentRequestNoticeStore(preferences);
      expect(await first.wasRead('one', rejected), false);
      await first.markRead('one', rejected);
      final reopened = LocalStudentRequestNoticeStore(preferences);
      expect(await reopened.wasRead('one', rejected), true);
      expect(await reopened.wasRead('two', rejected), false);
      expect(
        await reopened.wasRead(
          'one',
          fixtures.row(state: 'RECHAZADA', revision: 2),
        ),
        false,
      );
      expect(
        await reopened.wasRead(
          'one',
          fixtures.row(
            id: fixtures.institutionId,
            state: 'RECHAZADA',
            revision: 1,
          ),
        ),
        false,
      );
      expect(preferences.values.values.single, '${fixtures.requestId}:1');
    },
  );
  testWidgets('sin solicitudes no ocupa un lugar en Más', (tester) async {
    await mount(tester, fixtures.RequestFake());
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Mis solicitudes de ingreso'), findsNothing);
  });
  testWidgets('pendiente muestra solo acceso contextual y permite consultar', (
    tester,
  ) async {
    final repo = fixtures.RequestFake()..rows = [fixtures.row()];
    await mount(tester, repo);
    expect(find.text('Solicitud de ingreso · Pendiente'), findsOneWidget);
    await tester.tap(find.byTooltip('Actualizar estado de ingreso'));
    await tester.pumpAndSettle();
    expect(repo.pages, hasLength(2));
  });
  testWidgets('aprobada o cancelada desaparecen del acceso rápido', (
    tester,
  ) async {
    final repo = fixtures.RequestFake()
      ..rows = [fixtures.row(state: 'APROBADA', revision: 1)];
    await mount(tester, repo);
    expect(find.byType(ListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    repo.rows = [fixtures.row(state: 'CANCELADA', revision: 1)];
    await mount(tester, repo);
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets('vinculado y demo no consultan historial ni muestran acceso', (
    tester,
  ) async {
    final repo = fixtures.RequestFake()..failRead = true;
    await mount(
      tester,
      repo,
      user: const UserSession(
        id: 'linked',
        firstName: 'Alumno',
        role: AppRole.student,
        institutionId: fixtures.institutionId,
      ),
    );
    expect(repo.pages, isEmpty);
    expect(find.byType(ListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await mount(
      tester,
      repo,
      user: const UserSession(
        id: 'demo',
        firstName: 'Demo',
        role: AppRole.student,
        isDemo: true,
      ),
    );
    expect(repo.pages, isEmpty);
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets(
    'rechazo se conserva hasta mostrar resultado; consultar no borra historial',
    (tester) async {
      final preferences = NoticePreferences();
      final repo = fixtures.RequestFake()
        ..rows = [fixtures.row(state: 'RECHAZADA', revision: 1)];
      await mount(tester, repo, preferences: preferences);
      expect(find.text('Respuesta a tu solicitud de ingreso'), findsOneWidget);
      expect(preferences.values, isEmpty);
      await tester.tap(find.text('Respuesta a tu solicitud de ingreso'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('rechazó tu solicitud de ingreso'),
        findsOneWidget,
      );
      expect(preferences.values, hasLength(1));
      expect(repo.rows.single.status, StudentRequestStatus.rejected);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Respuesta a tu solicitud de ingreso'), findsNothing);
    },
  );
  testWidgets(
    'cancelar pendiente retira acceso al volver sin borrar registro',
    (tester) async {
      final repo = fixtures.RequestFake()..rows = [fixtures.row()];
      await mount(tester, repo);
      await tester.tap(find.text('Solicitud de ingreso · Pendiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar solicitud'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repo.rows.single.status, StudentRequestStatus.cancelled);
      expect(find.byType(ListTile), findsNothing);
    },
  );
  testWidgets('fallo de red muestra reintento, no pendiente ficticio', (
    tester,
  ) async {
    final repo = fixtures.RequestFake()..failRead = true;
    await mount(tester, repo);
    expect(find.text('No pudimos consultar el ingreso'), findsOneWidget);
    expect(find.text('Solicitud de ingreso · Pendiente'), findsNothing);
    repo.failRead = false;
    repo.rows = [fixtures.row()];
    await tester.tap(find.byTooltip('Reintentar consulta de ingreso'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitud de ingreso · Pendiente'), findsOneWidget);
  });
  testWidgets(
    'fallo al recordar lectura mantiene aviso y no oculta resultado',
    (tester) async {
      final preferences = NoticePreferences(failRead: true, failWrite: true);
      final repo = fixtures.RequestFake()
        ..rows = [fixtures.row(state: 'RECHAZADA', revision: 1)];
      await mount(tester, repo, preferences: preferences);
      await tester.tap(find.text('Respuesta a tu solicitud de ingreso'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('rechazó tu solicitud de ingreso'),
        findsOneWidget,
      );
      expect(
        find.textContaining('no pudimos recordar su lectura'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Respuesta a tu solicitud de ingreso'), findsOneWidget);
    },
  );
  testWidgets('respuesta tardía de otra cuenta no reaparece en el menú', (
    tester,
  ) async {
    final repo = fixtures.RequestFake()
      ..delayed = Completer<StudentInstitutionRequestPage>();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => ShortcutSession(fixtures.student),
        ),
        studentInstitutionRequestRepositoryProvider.overrideWithValue(repo),
        studentRequestNoticeStoreProvider.overrideWithValue(
          LocalStudentRequestNoticeStore(NoticePreferences()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: StudentRequestShortcut()),
        ),
      ),
    );
    await tester.pump();
    final old = repo.delayed!;
    repo.delayed = null;
    (container.read(sessionControllerProvider.notifier) as ShortcutSession)
        .change(
          const UserSession(
            id: 'new',
            firstName: 'Otra cuenta',
            role: AppRole.student,
          ),
        );
    await tester.pumpAndSettle();
    old.complete(
      StudentInstitutionRequestPage(
        items: [fixtures.row()],
        page: 1,
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets(
    'institución aceptada sin grupo no se muestra como desvinculada',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            institutionGroupRepositoryProvider.overrideWithValue(
              LinkedNoGroups(),
            ),
          ],
          child: const MaterialApp(home: StudentGroupJoinPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Institución vinculada'), findsOneWidget);
      expect(find.text('Sin institución vinculada'), findsNothing);
      expect(
        find.textContaining('todavía no tienes grupos asignados'),
        findsOneWidget,
      );
    },
  );
}
