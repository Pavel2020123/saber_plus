import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:saber_plus/core/widgets/academic_option_content.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/battles/domain/battle_models.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_online_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

const path = '/recursos/editoriales/a6ec3648-24ee-47d0-91f8-e59b2b68b9ab';
const option = {'id': 'a', 'texto': 'Rectángulo de dos por uno'};

void main() {
  final readers = <String, String? Function(Map<String, dynamic>)>{
    'práctica y juegos': (json) => PracticeOption.fromJson(json).imageUrl,
    'corrección': (json) => PracticeReviewOption.fromJson(json).imageUrl,
    'diagnóstico': (json) => DiagnosticOption.fromJson(json).imageUrl,
    'batallas': (json) => BattleAnswerOption.fromJson(json).imageUrl,
    'tira online': (json) => TugOnlineOption.fromJson(json).imageUrl,
    'historial': (json) => HistoryAnswer.fromJson(json).imageUrl,
    'cuaderno': (json) => NotebookAnswer.fromJson(json).imageUrl,
  };
  for (final entry in readers.entries) {
    test('${entry.key}: admite opciones antiguas sin imagen o con null', () {
      expect(entry.value({...option}), isNull);
      expect(entry.value({...option, 'imagenUrl': null}), isNull);
    });
    test('${entry.key}: conserva la referencia opcional de imagen', () {
      expect(entry.value({...option, 'imagenUrl': path}), path);
    });
  }
  test('serialización conserva sesiones antiguas y referencia al reabrir', () {
    expect(PracticeOption.fromJson({...option}).toJson(), option);
    final saved = PracticeOption.fromJson({
      ...option,
      'imagenUrl': path,
    }).toJson();
    expect(saved, {...option, 'imagenUrl': path});
    expect(PracticeOption.fromJson(saved).imageUrl, path);
    expect(saved.containsKey('esCorrecta'), isFalse);
  });

  testWidgets('opción solo de texto no solicita ni reserva espacio de imagen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AcademicOptionContent(text: 'Respuesta antigua')),
      ),
    );
    expect(find.text('Respuesta antigua'), findsOneWidget);
    expect(find.byType(AcademicImage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dos opciones comparten recurso sin ImageCache ni estirar sus píxeles',
    (tester) async {
      final image = (await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          base64Decode(
            'UklGRlgAAABXRUJQVlA4IEwAAADwBACdASp4ADwAPm02mUmkIyKhIQgAgA2JaQB2APwAABPPNPcaiVea2vp06dOnRwAA/us2///1aHy0Plofuff//mCV+QbrkAAAAAAA',
          ),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      }))!;
      addTearDown(image.dispose);
      final cached = PaintingBinding.instance.imageCache.currentSize;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorialImageProvider(path).overrideWith((ref) async => image),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  AcademicOptionContent(text: 'Opción A', imageUrl: path),
                  AcademicOptionContent(text: 'Opción B', imageUrl: path),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsNWidgets(2));
      for (final raw in tester.widgetList<RawImage>(find.byType(RawImage))) {
        expect(raw.image!.width / raw.image!.height, 2);
        expect(raw.fit, BoxFit.contain);
      }
      expect(find.byType(Image), findsNothing);
      expect(PaintingBinding.instance.imageCache.currentSize, cached);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'error completo a 320px y texto2x; reintentar no selecciona la respuesta',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selections = 0, loads = 0;
      const description =
          'Rectángulo de dos unidades de ancho por una de alto con datos para comparar proporciones';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorialImageProvider(path).overrideWith((ref) async {
              loads++;
              throw StateError('Sin conexión de ensayo');
            }),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OutlinedButton(
                    onPressed: () => selections++,
                    child: const AcademicOptionContent(
                      text: description,
                      imageUrl: path,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final failure = find.textContaining(
        'Imagen de la opción: $description: no se pudo cargar.',
      );
      expect(failure, findsOneWidget);
      expect(tester.getSize(failure).height, greaterThan(240));
      expect(
        find.ancestor(of: failure, matching: find.byType(ClipRRect)),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Reintentar imagen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reintentar imagen'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(selections, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
