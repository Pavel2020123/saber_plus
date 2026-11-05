import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation_repository.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_illustration.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_page.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_providers.dart';
import 'package:saber_plus/features/profile/presentation/vocational_result_overview.dart';

const _capture = bool.fromEnvironment('CAPTURE_SABI_OV1D3B');
const _id = '00000000-0000-4000-8000-000000000001';
final _at = DateTime.utc(2026, 10, 19, 12);
final _families = vocationalFamilyNames.keys.toList();

// Synthetic server snapshots for presentation tests, not a client scorer.
VocationalResult _result({bool tie = false, bool cutoff = false}) {
  final scores = tie
      ? [80.0, 80.0, 75.0, 60.0, 30.0, 20.0]
      : cutoff
      ? [90.0, 80.0, 75.0, 75.0, 40.0, 30.0]
      : [90.0, 60.0, 80.0, 40.0, 85.0, 30.0];
  const activities = [
    'Crear soluciones tecnológicas',
    'Cuidar la salud',
    'Comprender la sociedad',
    'Organizar un proyecto',
    'Enseñar y aprender idiomas',
    'Diseñar y cuidar el entorno',
  ];
  const prefixes = ['T', 'S', 'C', 'N', 'H', 'D'];
  final questions = [
    for (var f = 0; f < 6; f++)
      for (var n = 1; n <= 5; n++)
        VocationalQuestion(
          id: '${prefixes[f]}$n',
          text: '${activities[f]} ($n)',
          family: _families[f],
        ),
  ];
  return VocationalResult(
    version: 1,
    validCount: 30,
    totalQuestions: 30,
    families: [
      for (var i = 0; i < 6; i++)
        VocationalFamilyResult(
          id: _families[i],
          validCount: 5,
          totalQuestions: 5,
          score: scores[i],
        ),
    ],
    mainFamilies: cutoff
        ? _families.take(4).toList()
        : tie
        ? _families.take(3).toList()
        : [_families[0], _families[4], _families[2]],
    completedAt: _at,
    questions: questions,
    answers: {for (final q in questions) q.id: VocationalAnswer.much},
  );
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'visual-test', firstName: 'Ana', role: AppRole.student),
  );
}

class _Repository implements VocationalOrientationRepository {
  _Repository(this.result);
  final VocationalResult result;
  int writes = 0;
  VocationalAttempt get attempt => VocationalAttempt(
    id: _id,
    version: 1,
    completed: true,
    startedAt: _at,
    updatedAt: _at,
    completedAt: _at,
    answers: result.answers,
    result: result,
  );
  @override
  Future<VocationalQuestionnaire> questionnaire() async =>
      VocationalQuestionnaire(version: 1, questions: result.questions);
  @override
  Future<VocationalAttempt?> current() async => null;
  @override
  Future<VocationalHistory> history(int page) async =>
      VocationalHistory(page: 1, pageSize: 20, total: 1, attempts: [attempt]);
  @override
  Future<VocationalAttempt> getAttempt(String id) async {
    expect(id, _id);
    return attempt;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    writes++;
    throw StateError('Unexpected mutation: ${invocation.memberName}');
  }
}

ThemeData _theme(ThemeData theme) {
  final button = theme.filledButtonTheme.style!;
  final text = button.textStyle!.resolve(<WidgetState>{})!;
  return theme.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: button.copyWith(
        textStyle: WidgetStatePropertyAll(text.copyWith(fontFamily: 'Roboto')),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  bool dark = false,
  double scale = 1,
  GlobalKey? boundary,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_Session.new),
        vocationalOrientationRepositoryProvider.overrideWithValue(repository),
        vocationalOfficialLinkOpenerProvider.overrideWithValue(
          (_) async => true,
        ),
      ],
      child: RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _theme(SaberPlusTheme.light),
          darkTheme: _theme(SaberPlusTheme.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const VocationalOrientationPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, 'vocational-open-history');
  await _tap(tester, 'vocational-history-$_id');
  expect(find.byKey(const Key('vocational-result')), findsOneWidget);
}

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double alignment = .05,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 100,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: alignment);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('editorial table matches all six owner-approved mappings exactly', () {
    expect(vocationalRelatedProfessions, {
      _families[0]: [
        SabiProfession.software,
        SabiProfession.industrialEngineering,
        SabiProfession.civilEngineering,
      ],
      _families[1]: [
        SabiProfession.medicine,
        SabiProfession.nursing,
        SabiProfession.psychology,
      ],
      _families[2]: [
        SabiProfession.law,
        SabiProfession.psychology,
        SabiProfession.design,
      ],
      _families[3]: [
        SabiProfession.administration,
        SabiProfession.accounting,
        SabiProfession.industrialEngineering,
      ],
      _families[4]: [
        SabiProfession.education,
        SabiProfession.psychology,
        SabiProfession.law,
      ],
      _families[5]: [
        SabiProfession.design,
        SabiProfession.environmentalAgro,
        SabiProfession.civilEngineering,
      ],
    });
  });

  testWidgets(
    'normal summary preserves three main families, six server indices, details and no mutations',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final snapshot = _result();
        final repo = _Repository(snapshot);
        await _open(tester, repo);
        for (final id in snapshot.mainFamilies) {
          expect(find.byKey(Key('vocational-family-$id')), findsOneWidget);
        }
        expect(
          find.byKey(Key('vocational-family-${_families[1]}')),
          findsNothing,
        );
        await _reveal(tester, find.byType(SabiProfessionIllustration));
        final image = tester.getSemantics(
          find.byType(SabiProfessionIllustration),
        );
        expect(image.getSemanticsData().flagsCollection.isImage, isTrue);
        expect(image.childrenCount, 0);
        expect(
          tester
              .widget<SabiProfessionIllustration>(
                find.byType(SabiProfessionIllustration),
              )
              .profession,
          SabiProfession.software,
        );
        for (final f in snapshot.families) {
          final node = find.byKey(Key('vocational-score-${f.id}'));
          await _reveal(tester, node);
          final label = tester.getSemantics(node).label;
          expect(label, contains(vocationalFamilyNames[f.id]!));
          expect(
            label,
            contains('Puntaje de interés: ${f.score.toInt()} de 100'),
          );
          expect(label, contains('Cobertura: 5 de 5'));
        }
        expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
        final bars = tester.widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(
          bars.map((b) => b.value),
          snapshot.families.map((f) => f.score / 100),
        );
        await _tap(tester, 'vocational-result-details');
        expect(
          find.text('Marcaste interés en: Crear soluciones tecnológicas (1)'),
          findsOneWidget,
        );
        expect(find.textContaining('Marcaste interés en:'), findsNWidgets(30));
        await _reveal(
          tester,
          find.byKey(const Key('vocational-official-programs')),
        );
        expect(find.byKey(const Key('vocational-repeat')), findsOneWidget);
        expect(repo.writes, 0);
        expect(repo.result, same(snapshot));
        final copy = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ')
            .toLowerCase();
        for (final term in [
          'carrera ideal',
          'recomendamos',
          'eres apto',
          'probabilidad de éxito',
          '%',
        ]) {
          expect(copy, isNot(contains(term)));
        }
        expect(copy, contains('no es una recomendación de carrera'));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final cutoff in [false, true]) {
    testWidgets('ties preserved: cutoff=$cutoff, no unique winning family', (
      tester,
    ) async {
      final snapshot = _result(tie: !cutoff, cutoff: cutoff);
      final repo = _Repository(snapshot);
      await _open(tester, repo);
      for (final id in snapshot.mainFamilies) {
        expect(find.byKey(Key('vocational-family-$id')), findsOneWidget);
      }
      if (!cutoff) {
        expect(
          find.textContaining('Hay empate en el mayor puntaje'),
          findsOneWidget,
        );
        final expected = {
          ...vocationalRelatedProfessions[_families[0]]!,
          ...vocationalRelatedProfessions[_families[1]]!,
        }.toList();
        for (var i = 0; i < expected.length; i++) {
          expect(
            tester
                .widget<SabiProfessionIllustration>(
                  find.byType(SabiProfessionIllustration),
                )
                .profession,
            expected[i],
          );
          if (i + 1 < expected.length) {
            await _tap(tester, 'vocational-featured-next');
          }
        }
      } else {
        expect(snapshot.mainFamilies, hasLength(4));
        expect(
          find.textContaining('Hay empate en el mayor puntaje'),
          findsNothing,
        );
      }
      expect(repo.writes, 0);
      expect(snapshot.mainFamilies, repo.result.mainFamilies);
    });
  }

  testWidgets(
    'related selector uses main families, deduplicates props, preserves all relations and targets',
    (tester) async {
      final snapshot = _result();
      final repo = _Repository(snapshot);
      await _open(tester, repo);
      await _tap(tester, 'vocational-related-toggle');
      final expected = {
        for (final id in snapshot.mainFamilies)
          ...vocationalRelatedProfessions[id]!,
      }.toList();
      for (var i = 0; i < expected.length; i++) {
        final name = find.byKey(const Key('vocational-related-name'));
        expect(tester.widget<Text>(name).data, expected[i].displayName);
        final explorer = find
            .ancestor(of: name, matching: find.byType(Column))
            .first;
        for (final id in snapshot.mainFamilies.where(
          (id) => vocationalRelatedProfessions[id]!.contains(expected[i]),
        )) {
          expect(
            find.descendant(
              of: explorer,
              matching: find.text(
                'Relacionado con ${vocationalFamilyNames[id]}',
              ),
            ),
            findsOneWidget,
          );
        }
        for (final key in [
          'vocational-related-previous',
          'vocational-related-next',
        ]) {
          expect(
            tester.getSize(find.byKey(Key(key))).height,
            greaterThanOrEqualTo(48),
          );
        }
        if (i + 1 < expected.length) {
          await _tap(tester, 'vocational-related-next');
        }
      }
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('vocational-related-next')),
            )
            .onPressed,
        isNull,
      );
      expect(repo.writes, 0);
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'result 320x640, text=$scale dark=$dark, no overflow, scroll and semantic headings',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            final repo = _Repository(_result(tie: true));
            await _open(tester, repo, dark: dark, scale: scale);
            for (final id in repo.result.mainFamilies) {
              final heading = find.byKey(Key('vocational-family-heading-$id'));
              await _reveal(tester, heading);
              expect(
                tester
                    .getSemantics(heading)
                    .getSemanticsData()
                    .flagsCollection
                    .isHeader,
                isTrue,
              );
            }
            await _tap(tester, 'vocational-related-toggle');
            await _tap(tester, 'vocational-related-next');
            await _tap(tester, 'vocational-result-details');
            for (final f in repo.result.families) {
              await _reveal(
                tester,
                find.byKey(Key('vocational-score-${f.id}')),
              );
            }
            await _reveal(
              tester,
              find.byKey(const Key('vocational-official-programs')),
            );
            expect(tester.takeException(), isNull);
            expect(repo.writes, 0);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'opt-in D3B captures from real page with synthetic historical snapshots',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(_loadFonts);
      for (final scenario in [
        (
          name: 'result_normal',
          target: 'vocational-result',
          tie: false,
          width: 390.0,
          scale: 1.0,
          dark: false,
        ),
        (
          name: 'result_sabi',
          target: 'vocational-featured-name',
          tie: false,
          width: 390.0,
          scale: 1.0,
          dark: false,
        ),
        (
          name: 'result_related',
          target: 'vocational-related-toggle',
          tie: false,
          width: 390.0,
          scale: 1.0,
          dark: false,
        ),
        (
          name: 'result_tie',
          target: 'vocational-family-${_families[0]}',
          tie: true,
          width: 390.0,
          scale: 1.0,
          dark: false,
        ),
        (
          name: 'result_small',
          target: 'vocational-featured-name',
          tie: false,
          width: 320.0,
          scale: 1.0,
          dark: false,
        ),
        (
          name: 'result_text_200',
          target: 'vocational-featured-name',
          tie: true,
          width: 320.0,
          scale: 2.0,
          dark: false,
        ),
        (
          name: 'result_dark',
          target: 'vocational-featured-name',
          tie: false,
          width: 390.0,
          scale: 1.0,
          dark: true,
        ),
        (
          name: 'result_scores',
          target: 'vocational-score-${_families[0]}',
          tie: false,
          width: 390.0,
          scale: 1.0,
          dark: false,
        ),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = Size(
          scenario.width,
          scenario.width == 320 ? 640 : 844,
        );
        final repo = _Repository(_result(tie: scenario.tie));
        final boundary = GlobalKey();
        await _open(
          tester,
          repo,
          dark: scenario.dark,
          scale: scenario.scale,
          boundary: boundary,
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(SabiProfessionIllustration.canonicalAsset),
            tester.element(find.byType(VocationalOrientationPage)),
          ),
        );
        if (scenario.name == 'result_related') {
          await _tap(tester, 'vocational-related-toggle');
        }
        await _reveal(tester, find.byKey(Key(scenario.target)), alignment: 0);
        void repaint(RenderObject obj) {
          obj.markNeedsPaint();
          obj.visitChildren(repaint);
        }

        repaint(boundary.currentContext!.findRenderObject()!);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(repo.writes, 0);
        await tester.runAsync(() async {
          if (!_capture) throw StateError('Capture is opt-in');
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('build/sabi-vocational-d3b/${scenario.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
    },
    skip: !_capture,
  );
}

Future<void> _loadFonts() async {
  var directory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final fonts = Directory('${directory.path}/artifacts/material_fonts');
    if (await File('${fonts.path}/roboto-regular.ttf').exists()) {
      for (final family in ['Roboto', 'MaterialIcons']) {
        final loader = FontLoader(family);
        for (final name
            in family == 'Roboto'
                ? [
                    'roboto-regular.ttf',
                    'roboto-medium.ttf',
                    'roboto-bold.ttf',
                    'roboto-black.ttf',
                  ]
                : ['materialicons-regular.otf']) {
          loader.addFont(
            Future.value(
              ByteData.sublistView(
                await File('${fonts.path}/$name').readAsBytes(),
              ),
            ),
          );
        }
        await loader.load();
      }
      return;
    }
    directory = directory.parent;
  }
  throw StateError('Flutter capture fonts unavailable');
}
