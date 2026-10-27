import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:saber_plus/core/widgets/academic_option_content.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_models.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_repository.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_duel_providers.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_page.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  for (final ghost in [false, true]) {
    for (final width in [320.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${ghost ? 'Fantasma' : 'Trivia'} contiene opciones a $width/$scale',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 2400));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final images = (await tester.runAsync(() async {
              final result = <ui.Image>[];
              for (final size in [const Size(160, 80), const Size(80, 160)]) {
                final recorder = ui.PictureRecorder();
                Canvas(
                  recorder,
                ).drawRect(Offset.zero & size, Paint()..color = Colors.blue);
                final picture = recorder.endRecording();
                result.add(
                  await picture.toImage(
                    size.width.toInt(),
                    size.height.toInt(),
                  ),
                );
                picture.dispose();
              }
              return result;
            }))!;
            addTearDown(() {
              for (final image in images) {
                image.dispose();
              }
            });
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  triviaRushRepositoryProvider.overrideWithValue(_Questions()),
                  ghostDuelUserIdProvider.overrideWithValue('student-test'),
                  ghostDuelRepositoryProvider.overrideWithValue(_NoGhost()),
                  editorialImageProvider(
                    '/recursos/editoriales/11111111-1111-4111-8111-111111111111',
                  ).overrideWith((ref) async => images[0]),
                  editorialImageProvider(
                    '/recursos/editoriales/22222222-2222-4222-8222-222222222222',
                  ).overrideWith((ref) async => images[1]),
                ],
                child: MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: TriviaRushPage(
                    ghostMode: ghost,
                    config: const TriviaRushConfig(
                      areas: [AcademicArea.mathematics],
                      duration: TriviaRushDuration.quick,
                    ),
                  ),
                ),
              ),
            );
            for (var pump = 0; pump < 15; pump++) {
              await tester.pump(const Duration(milliseconds: 10));
            }
            expect(find.byType(AcademicOptionContent), findsNWidgets(2));
            for (final id in ['blue', 'orange']) {
              final button = find.byKey(Key('trivia-answer-$id'));
              final material = find
                  .descendant(of: button, matching: find.byType(Material))
                  .first;
              final border = tester.widget<Material>(material).shape!;
              final bounds = tester.getRect(material);
              final outline = border.getOuterPath(Offset.zero & bounds.size);
              final content = find.descendant(
                of: button,
                matching: find.byType(AcademicOptionContent),
              );
              for (final type in [Text, RawImage]) {
                final part = find.descendant(
                  of: content,
                  matching: find.byType(type),
                );
                expect(part, findsOneWidget);
                final rect = tester
                    .getRect(part)
                    .shift(-bounds.topLeft)
                    .deflate(1);
                for (final point in [
                  rect.topLeft,
                  rect.topRight,
                  rect.bottomLeft,
                  rect.bottomRight,
                ]) {
                  expect(
                    outline.contains(point),
                    isTrue,
                    reason: '$id: $type $rect fuera del contorno $border',
                  );
                }
              }
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}

class _Questions implements TriviaRushRepository {
  @override
  Future<TriviaRushSession> start(
    TriviaRushConfig config,
  ) async => const TriviaRushSession(
    attemptId: 'bounds-test',
    questions: [
      PracticeQuestion(
        id: 'rectangles',
        statement: 'Elige el rectángulo horizontal',
        difficulty: 'BASICA',
        subtopicId: 'figures',
        subtopicName: 'Figuras',
        themeName: 'Proporciones',
        area: AcademicArea.mathematics,
        options: [
          PracticeOption(
            id: 'blue',
            text: 'Rectángulo azul horizontal',
            imageUrl:
                '/recursos/editoriales/11111111-1111-4111-8111-111111111111',
          ),
          PracticeOption(
            id: 'orange',
            text: 'Rectángulo naranja vertical',
            imageUrl:
                '/recursos/editoriales/22222222-2222-4222-8222-222222222222',
          ),
        ],
      ),
    ],
  );

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) => throw UnimplementedError();

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) => throw UnimplementedError();
}

class _NoGhost implements GhostDuelRepository {
  @override
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  }) async => null;

  @override
  Future<GhostSaveResult> saveIfBetter(GhostRun run) =>
      throw UnimplementedError();
}
