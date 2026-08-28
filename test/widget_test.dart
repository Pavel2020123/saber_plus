import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/app.dart';
import 'package:saber_plus/core/storage/secure_session_store.dart';

class _FakeSecureSessionStore extends SecureSessionStore {
  _FakeSecureSessionStore() : super(const FlutterSecureStorage());

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> clear() async {}
}

Widget _testApp() => ProviderScope(
  overrides: [
    secureSessionStoreProvider.overrideWithValue(_FakeSecureSessionStore()),
  ],
  child: const SaberPlusApp(),
);

void main() {
  testWidgets('muestra la bienvenida de SaberPlus', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme?.scaffoldBackgroundColor, Colors.white);
    expect(find.text('SaberPlus'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.textContaining('Tu preparación ICFES'), findsOneWidget);
  });

  testWidgets('permite entrar al dashboard demostrativo', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Qué bueno verte'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola, Santiago'), findsOneWidget);
    expect(find.text('Refuerzo de matemáticas'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('abre registro y recuperación desde el ingreso', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Crear una cuenta'));
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.text('Recupera tu cuenta'), findsOneWidget);
  });

  testWidgets('navega por área, tema, subtema y lección demostrativa', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido por área'), findsOneWidget);

    await tester.tap(find.byKey(const Key('study-area-matematicas')));
    await tester.pumpAndSettle();
    expect(find.text('Razones y proporciones'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('study-subtopic-demo-mathematics-subtopic')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Regla de tres'), findsWidgets);
    expect(find.text('Marcar como completada'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('complete-study-lesson-button')),
    );
    await tester.tap(find.byKey(const Key('complete-study-lesson-button')));
    await tester.pumpAndSettle();
    expect(find.text('Lección completada'), findsOneWidget);
  });
}
