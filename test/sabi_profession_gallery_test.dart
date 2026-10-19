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
import 'package:saber_plus/features/profile/presentation/sabi_profession_gallery.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_illustration.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_page.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_providers.dart';

const _capture = bool.fromEnvironment('CAPTURE_SABI_OV1D3A');

class _VisualSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'local-visual-review',
      firstName: 'Revisión',
      role: AppRole.student,
    ),
  );
}

// Only supplies the real page's introduction. No Backend, private data or
// invented result. Any attempt, answer, history or scoring operation fails.
class _VisualRepository implements VocationalOrientationRepository {
  int unexpectedActions = 0;
  int questionnaireReads = 0;

  @override
  Future<VocationalQuestionnaire> questionnaire() async {
    questionnaireReads++;
    const prefixes = ['T', 'S', 'C', 'N', 'H', 'D'];
    return VocationalQuestionnaire(
      version: 1,
      questions: [
        for (var family = 0; family < 6; family++)
          for (var question = 1; question <= 5; question++)
            VocationalQuestion(
              id: '${prefixes[family]}$question',
              text: 'Actividad de prueba local',
              family: vocationalFamilyNames.keys.elementAt(family),
            ),
      ],
    );
  }

  @override
  Future<VocationalAttempt?> current() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedActions++;
    throw StateError(
      'Visual exploration must not call ${invocation.memberName}',
    );
  }
}

Future<void> _loadCaptureFonts() async {
  // Reuse the SDK font-loading approach of the prototype captures. Widget
  // tests otherwise render Ahem blocks, which cannot serve as copy evidence.
  var directory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final fonts = Directory('${directory.path}/artifacts/material_fonts');
    if (await File('${fonts.path}/roboto-regular.ttf').exists()) {
      for (final family in ['Roboto', 'MaterialIcons']) {
        final loader = FontLoader(family);
        for (final file
            in family != 'MaterialIcons'
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
                await File('${fonts.path}/$file').readAsBytes(),
              ),
            ),
          );
        }
        await loader.load();
      }
      return;
    }
    if (directory.parent.path == directory.path) break;
    directory = directory.parent;
  }
  throw StateError('Cannot locate Flutter SDK fonts for visual review');
}

ThemeData _captureTheme(ThemeData theme) {
  // The real Android fallback is Roboto; the test engine fallback is Ahem.
  // Resolve only the CTA's unspecified font family for readable screenshots,
  // retaining its actual size, weight, colors and geometry from the app theme.
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

Future<void> _writeCapture(GlobalKey key, String name) async {
  const allowed = {
    'intro_gallery_closed',
    'intro_gallery_open',
    'gallery_selected',
    'gallery_small',
    'gallery_small_context',
    'gallery_text_200',
    'gallery_text_200_context',
    'gallery_dark',
  };
  if (!_capture || !allowed.contains(name)) {
    throw StateError(
      'D3A capture is opt-in and confined to approved build paths',
    );
  }
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = File('build/sabi-vocational-d3a/$name.png');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Future<void> _capturePage(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  // Paint a complete frame after loading fonts and precaching the canonical
  // image, before reading pixels for human review.
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(key.currentContext!.findRenderObject()!);
  await tester.pump();
  await tester.runAsync(() => _writeCapture(key, name));
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final dark in [false, true]) {
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      testWidgets(
        'D3A gallery: dark=$dark, size=$size, text 200%, complete neutral catalog',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: SaberPlusTheme.light,
                darkTheme: SaberPlusTheme.dark,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const Scaffold(
                  body: SingleChildScrollView(child: SabiProfessionGallery()),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(SabiProfessionIllustration), findsNothing);
            expect(
              find.textContaining('independiente de tus respuestas'),
              findsOneWidget,
            );
            expect(
              find.textContaining('no recomienda una carrera'),
              findsOneWidget,
            );
            expect(
              tester
                  .getSize(find.byKey(const Key('sabi-gallery-toggle')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            await _tap(tester, 'sabi-gallery-toggle');
            expect(
              tester
                  .widget<OutlinedButton>(
                    find.byKey(const Key('sabi-gallery-previous')),
                  )
                  .onPressed,
              isNull,
            );
            final labels = <String>{};
            for (var index = 0; index < SabiProfession.values.length; index++) {
              final profession = SabiProfession.values[index];
              expect(
                tester
                    .widget<Text>(find.byKey(const Key('sabi-gallery-title')))
                    .data,
                profession.displayName,
              );
              expect(find.text('Ámbito ${index + 1} de 12'), findsOneWidget);
              final illustration = find.byType(SabiProfessionIllustration);
              expect(illustration, findsOneWidget);
              expect(
                tester
                    .widget<SabiProfessionIllustration>(illustration)
                    .profession,
                profession,
              );
              await tester.ensureVisible(illustration);
              await tester.pumpAndSettle();
              final image = tester.getSemantics(illustration);
              expect(image.getSemanticsData().flagsCollection.isImage, isTrue);
              expect(image.childrenCount, 0);
              labels.add(image.label);
              final position = tester.getSemantics(
                find.byKey(const Key('sabi-gallery-position')),
              );
              expect(
                position.getSemanticsData().flagsCollection.isLiveRegion,
                isTrue,
              );
              for (final key in [
                'sabi-gallery-previous',
                'sabi-gallery-next',
              ]) {
                expect(
                  tester.getSize(find.byKey(Key(key))).height,
                  greaterThanOrEqualTo(48),
                );
                expect(
                  tester.getSize(find.byKey(Key(key))).width,
                  greaterThanOrEqualTo(48),
                );
              }
              if (index < SabiProfession.values.length - 1) {
                await _tap(tester, 'sabi-gallery-next');
              }
              expect(tester.takeException(), isNull);
            }
            expect(labels, hasLength(12));
            expect(
              tester
                  .widget<OutlinedButton>(
                    find.byKey(const Key('sabi-gallery-next')),
                  )
                  .onPressed,
              isNull,
            );
            await _tap(tester, 'sabi-gallery-previous');
            expect(
              tester
                  .widget<SabiProfessionIllustration>(
                    find.byType(SabiProfessionIllustration),
                  )
                  .profession,
              SabiProfession.design,
            );
            await _tap(tester, 'sabi-gallery-toggle');
            expect(find.byType(SabiProfessionIllustration), findsNothing);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('opt-in captures of the real vocational introduction', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(_loadCaptureFonts);
    for (final scenario in [
      (
        name: 'intro_gallery_closed',
        size: const Size(390, 844),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'intro_gallery_open',
        size: const Size(390, 844),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'gallery_selected',
        size: const Size(390, 844),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'gallery_small',
        size: const Size(320, 640),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'gallery_text_200',
        size: const Size(320, 640),
        scale: 2.0,
        dark: false,
      ),
      (
        name: 'gallery_dark',
        size: const Size(390, 844),
        scale: 1.0,
        dark: true,
      ),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.physicalSize = scenario.size;
      final repository = _VisualRepository();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_VisualSession.new),
            vocationalOrientationRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _captureTheme(SaberPlusTheme.light),
              darkTheme: _captureTheme(SaberPlusTheme.dark),
              themeMode: scenario.dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
                child: child!,
              ),
              home: const VocationalOrientationPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vocational-intro')), findsOneWidget);
      expect(find.byType(SabiProfessionIllustration), findsNothing);
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(SabiProfessionIllustration.canonicalAsset),
          tester.element(find.byType(VocationalOrientationPage)),
        ),
      );
      if (scenario.name != 'intro_gallery_closed') {
        final scrollable = find
            .descendant(
              of: find.byKey(const Key('vocational-intro')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(const Key('sabi-gallery-toggle')),
          180,
          scrollable: scrollable,
        );
        await _tap(tester, 'sabi-gallery-toggle');
        if (scenario.name == 'gallery_selected') {
          for (var i = 0; i < SabiProfession.design.index; i++) {
            await _tap(tester, 'sabi-gallery-next');
          }
          expect(
            tester
                .widget<SabiProfessionIllustration>(
                  find.byType(SabiProfessionIllustration),
                )
                .profession,
            SabiProfession.design,
          );
        }
        await Scrollable.ensureVisible(
          tester.element(
            find.byKey(const Key('vocational-profession-gallery')),
          ),
          alignment: 0,
        );
        await tester.pumpAndSettle();
        if (scenario.name == 'gallery_small' ||
            scenario.name == 'gallery_text_200') {
          await _capturePage(tester, boundary, '${scenario.name}_context');
          await Scrollable.ensureVisible(
            tester.element(find.byKey(const Key('sabi-gallery-title'))),
            alignment: .03,
          );
          await tester.pumpAndSettle();
        }
      }
      expect(repository.questionnaireReads, 1);
      expect(repository.unexpectedActions, 0);
      expect(find.byKey(const Key('vocational-result')), findsNothing);
      expect(tester.takeException(), isNull);
      await _capturePage(tester, boundary, scenario.name);
    }
  }, skip: !_capture);
}
