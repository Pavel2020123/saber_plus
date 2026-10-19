import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation_repository.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_page.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_providers.dart';

const _id = '00000000-0000-4000-8000-000000000001';
const _at = '2026-10-15T12:00:00.000Z';
const _prefixes = ['T', 'S', 'C', 'N', 'H', 'D'];

List<Map<String, Object>> _questions() => [
  for (var family = 0; family < 6; family++)
    for (var number = 1; number <= 5; number++)
      {
        'id': '${_prefixes[family]}$number',
        'texto': 'Actividad ${_prefixes[family]}$number',
        'familia': vocationalFamilyNames.keys.elementAt(family),
      },
];

VocationalQuestionnaire _questionnaire() => VocationalQuestionnaire.parse({
  'rulesVersion': 1,
  'naturaleza': 'INTERESES_DECLARADOS',
  'preguntas': _questions(),
  'escala': [0, 1, 2, 3, 4, 'NO_SE'],
});

Map<String, Object?> _attempt({
  bool completed = false,
  List<Map<String, Object>> answers = const [],
}) {
  final finalAnswers = completed
      ? [
          for (final question in _questions())
            {'preguntaId': question['id']!, 'valor': 4},
        ]
      : answers;
  final result = completed
      ? {
          'ov1RulesVersion': 1,
          'naturaleza': 'INTERESES_DECLARADOS',
          'finalizable': true,
          'cantidadValidas': 30,
          'totalPreguntas': 30,
          'familias': [
            for (final family in vocationalFamilyNames.keys)
              {
                'familia': family,
                'cantidadValidas': 5,
                'totalPreguntas': 5,
                'puntaje': 80,
              },
          ],
          'principales': vocationalFamilyNames.keys.take(4).toList(),
          'completadoEn': _at,
          'preguntas': _questions(),
          'respuestas': finalAnswers,
        }
      : null;
  return {
    'id': _id,
    'rulesVersion': 1,
    'estado': completed ? 'COMPLETADO' : 'EN_PROGRESO',
    'iniciadoEn': _at,
    'actualizadoEn': _at,
    'completadoEn': completed ? _at : null,
    'respuestas': finalAnswers,
    'resultado': result,
  };
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'first', firstName: 'Ana', role: AppRole.student),
  );

  void switchAccount() {
    state = const SessionState.authenticated(
      UserSession(id: 'second', firstName: 'Luis', role: AppRole.student),
    );
  }
}

class _Repository implements VocationalOrientationRepository {
  VocationalAttempt? active;
  VocationalAttempt? completed;
  bool failLoad = false;
  bool failSave = false;
  bool failHistory = false;
  bool insufficient = false;

  @override
  Future<VocationalQuestionnaire> questionnaire() async {
    if (failLoad) {
      throw const ApiError(code: 'network_unavailable', message: 'Sin red.');
    }
    return _questionnaire();
  }

  @override
  Future<VocationalAttempt?> current() async => active;

  @override
  Future<VocationalAttempt> start() async =>
      active ??= VocationalAttempt.parse(_attempt());

  @override
  Future<VocationalAttempt> saveAnswer(
    String attemptId,
    String questionId,
    VocationalAnswer answer,
  ) async {
    if (failSave) {
      failSave = false;
      throw const ApiError(code: 'network_unavailable', message: 'Sin red.');
    }
    final answers = {
      for (final entry in active!.answers.entries) entry.key: entry.value,
      questionId: answer,
    };
    return active = VocationalAttempt.parse(
      _attempt(
        answers: [
          for (final entry in answers.entries)
            {'preguntaId': entry.key, 'valor': entry.value.wireValue},
        ],
      ),
    );
  }

  @override
  Future<VocationalAttempt> finish(String attemptId) async {
    if (insufficient) {
      throw const ApiError(
        code: 'COBERTURA_INSUFICIENTE',
        message: 'Cobertura insuficiente',
      );
    }
    completed = VocationalAttempt.parse(_attempt(completed: true));
    active = null;
    return completed!;
  }

  @override
  Future<VocationalHistory> history(int page) async {
    if (failHistory) {
      throw const ApiError(code: 'network_unavailable', message: 'Sin red.');
    }
    return VocationalHistory.parse({
      'pagina': page,
      'porPagina': 20,
      'total': completed == null ? 0 : 1,
      'intentos': [if (completed != null) _attempt(completed: true)],
    });
  }

  @override
  Future<VocationalAttempt> getAttempt(String attemptId) async => completed!;

  @override
  Future<void> deleteAttempt(String attemptId) async {
    completed = null;
  }
}

Widget _app(_Repository repository, {required bool dark}) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(_Session.new),
    vocationalOrientationRepositoryProvider.overrideWithValue(repository),
    vocationalOfficialLinkOpenerProvider.overrideWithValue((_) async => true),
  ],
  child: MaterialApp(
    theme: SaberPlusTheme.light,
    darkTheme: SaberPlusTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
      child: child!,
    ),
    home: const VocationalOrientationPage(),
  ),
);

void _smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await _reveal(tester, finder);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  const contentKeys = [
    'vocational-intro',
    'vocational-questionnaire',
    'vocational-result',
    'vocational-history',
  ];
  final content = contentKeys
      .map((key) => find.byKey(Key(key)))
      .firstWhere((candidate) => candidate.evaluate().isNotEmpty);
  final scrollable = find
      .descendant(of: content, matching: find.byType(Scrollable))
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final position = tester.state<ScrollableState>(scrollable).position;
    final step = position.viewportDimension * .8;
    await tester.scrollUntilVisible(
      finder,
      step,
      scrollable: scrollable,
      maxScrolls: (position.maxScrollExtent / step).ceil() + 3,
    );
  }
}

Future<void> _scan(WidgetTester tester, String key) async {
  final scrollable = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(Scrollable),
  );
  final target = scrollable.evaluate().isEmpty
      ? find.byKey(Key(key))
      : scrollable.first;
  expect(tester.takeException(), isNull);
  for (var index = 0; index < 12; index++) {
    await tester.drag(target, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('OV-1D1 320x640 text 200%, dark=$dark, all flow states', (
      tester,
    ) async {
      _smallScreen(tester);
      final repository = _Repository();
      await tester.pumpWidget(_app(repository, dark: dark));
      await tester.pumpAndSettle();
      await _scan(tester, 'vocational-intro');

      await _tap(tester, 'vocational-start');
      await _scan(tester, 'vocational-questionnaire');
      await _tap(tester, 'vocational-answer-little');
      await _scan(tester, 'vocational-questionnaire');
      repository.failSave = true;
      await _tap(tester, 'vocational-answer-much');
      await _scan(tester, 'vocational-questionnaire');
      await _tap(tester, 'vocational-retry-save');
      repository.insufficient = true;
      await _tap(tester, 'vocational-finish');
      expect(find.byKey(const Key('vocational-questionnaire')), findsOneWidget);
      await _scan(tester, 'vocational-questionnaire');

      repository.insufficient = false;
      await _tap(tester, 'vocational-finish');
      await _scan(tester, 'vocational-result');
      expect(find.byKey(const Key('vocational-result')), findsOneWidget);
      await _tap(tester, 'vocational-repeat');
      await _tap(tester, 'vocational-exit');
      await _tap(tester, 'vocational-open-history');
      await _scan(tester, 'vocational-history');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('progress and six answers expose an action and confirmed state', (
    tester,
  ) async {
    _smallScreen(tester);
    final semantics = tester.ensureSemantics();
    try {
      final repository = _Repository();
      await tester.pumpWidget(_app(repository, dark: false));
      await tester.pumpAndSettle();
      await _tap(tester, 'vocational-start');
      expect(
        tester.getSemantics(find.byKey(const Key('vocational-progress'))).label,
        'Pregunta 1 de 30',
      );
      for (final answer in VocationalAnswer.values) {
        await _reveal(
          tester,
          find.byKey(Key('vocational-answer-semantics-${answer.name}')),
        );
        final node = tester.getSemantics(
          find.byKey(Key('vocational-answer-semantics-${answer.name}')),
        );
        expect(node.label, answer.label);
        expect(node.value, 'Sin confirmar');
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('vocational-answer-semantics-unsure')),
            )
            .label,
        'No sé',
      );
      await _tap(tester, 'vocational-answer-little');
      final confirmed = tester.getSemantics(
        find.byKey(const Key('vocational-answer-semantics-little')),
      );
      expect(
        confirmed.getSemanticsData().flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(confirmed.value, 'Respuesta confirmada');

      repository.failSave = true;
      await _tap(tester, 'vocational-answer-much');
      await _reveal(
        tester,
        find.byKey(const Key('vocational-answer-semantics-little')),
      );
      final stillConfirmed = tester.getSemantics(
        find.byKey(const Key('vocational-answer-semantics-little')),
      );
      await _reveal(
        tester,
        find.byKey(const Key('vocational-answer-semantics-much')),
      );
      final pendingAnswer = tester.getSemantics(
        find.byKey(const Key('vocational-answer-semantics-much')),
      );
      expect(
        stillConfirmed.getSemanticsData().flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        pendingAnswer.getSemanticsData().flagsCollection.isSelected,
        isNot(ui.Tristate.isTrue),
      );
      expect(pendingAnswer.value, 'Sin confirmar');
      await _reveal(
        tester,
        find.byKey(const Key('vocational-pending-announcement')),
      );
      final pending = tester.getSemantics(
        find.byKey(const Key('vocational-pending-announcement')),
      );
      expect(pending.label, 'Pendiente de guardar: Me interesa mucho');
      expect(pending.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      await _reveal(tester, find.byKey(const Key('vocational-live-notice')));
      final error = tester.getSemantics(
        find.byKey(const Key('vocational-live-notice')),
      );
      expect(error.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(error.label, contains('No se guardó esta respuesta'));
      await _tap(tester, 'vocational-retry-save');
      await _reveal(
        tester,
        find.byKey(const Key('vocational-answer-semantics-much')),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const Key('vocational-answer-semantics-much')),
            )
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        find.byKey(const Key('vocational-pending-announcement')),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('load, coverage and history errors are live and editable', (
    tester,
  ) async {
    _smallScreen(tester);
    final semantics = tester.ensureSemantics();
    try {
      final repository = _Repository()..failLoad = true;
      await tester.pumpWidget(_app(repository, dark: false));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(const Key('vocational-live-notice')))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      repository.failLoad = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await _tap(tester, 'vocational-start');
      repository.insufficient = true;
      await _tap(tester, 'vocational-finish');
      await _reveal(tester, find.byKey(const Key('vocational-live-notice')));
      final coverage = tester.getSemantics(
        find.byKey(const Key('vocational-live-notice')),
      );
      expect(coverage.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(coverage.label, contains('faltan respuestas numéricas'));
      expect(find.byKey(const Key('vocational-questionnaire')), findsOneWidget);
      await _tap(tester, 'vocational-exit');
      repository.failHistory = true;
      await _tap(tester, 'vocational-open-history');
      await _reveal(tester, find.byKey(const Key('vocational-live-notice')));
      expect(
        tester
            .getSemantics(find.byKey(const Key('vocational-live-notice')))
            .label,
        'Sin red.',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'result and history labels protect privacy across account switch',
    (tester) async {
      _smallScreen(tester);
      final semantics = tester.ensureSemantics();
      try {
        final repository = _Repository();
        await tester.pumpWidget(_app(repository, dark: true));
        await tester.pumpAndSettle();
        await _tap(tester, 'vocational-start');
        await _tap(tester, 'vocational-finish');
        expect(find.textContaining('intereses declarados'), findsWidgets);
        expect(
          find.textContaining('no un diagnóstico ni una garantía'),
          findsWidgets,
        );
        for (final family in vocationalFamilyNames.keys.take(4)) {
          await tester.scrollUntilVisible(
            find.byKey(Key('vocational-family-heading-$family')),
            200,
          );
          final heading = tester.getSemantics(
            find.byKey(Key('vocational-family-heading-$family')),
          );
          expect(heading.getSemanticsData().flagsCollection.isHeader, isTrue);
          expect(heading.label, vocationalFamilyNames[family]);
        }
        final repeat = find.byKey(const Key('vocational-repeat'));
        await _reveal(tester, repeat);
        await tester.ensureVisible(repeat);
        expect(
          tester
              .widget<Text>(
                find.descendant(of: repeat, matching: find.byType(Text)),
              )
              .data,
          'Iniciar otra exploración de intereses',
        );
        await _tap(tester, 'vocational-repeat');
        await _tap(tester, 'vocational-exit');
        await _tap(tester, 'vocational-open-history');
        final open = tester.getSemantics(
          find.byKey(const Key('vocational-history-semantics-$_id')),
        );
        expect(open.label, contains('Abrir exploración completada'));
        expect(open.label, isNot(contains(_id)));
        expect(open.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        final delete = tester.getSemantics(
          find.byKey(const Key('vocational-delete-semantics-$_id')),
        );
        expect(delete.label, contains('Eliminar exploración completada'));
        expect(delete.label, isNot(contains(_id)));

        repository.completed = null;
        final container = ProviderScope.containerOf(
          tester.element(find.byType(VocationalOrientationPage)),
        );
        (container.read(sessionControllerProvider.notifier) as _Session)
            .switchAccount();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vocational-history')), findsNothing);
        expect(find.byKey(const Key('vocational-result')), findsNothing);
        expect(find.byKey(const Key('vocational-intro')), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('question options and primary actions keep 48 px touch targets', (
    tester,
  ) async {
    _smallScreen(tester);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository, dark: false));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(const Key('vocational-start')));
    expect(
      tester.getSize(find.byKey(const Key('vocational-start'))).height,
      greaterThanOrEqualTo(48),
    );
    await _tap(tester, 'vocational-start');
    await _reveal(tester, find.byKey(const Key('vocational-answer-much')));
    expect(
      tester.getSize(find.byKey(const Key('vocational-answer-much'))).height,
      greaterThanOrEqualTo(48),
    );
    await _tap(tester, 'vocational-next');
    await _reveal(tester, find.byKey(const Key('vocational-previous')));
    expect(
      tester.getSize(find.byKey(const Key('vocational-previous'))).height,
      greaterThanOrEqualTo(48),
    );
    await _reveal(tester, find.byKey(const Key('vocational-finish')));
    expect(
      tester.getSize(find.byKey(const Key('vocational-finish'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}
