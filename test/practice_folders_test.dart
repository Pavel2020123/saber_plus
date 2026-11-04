import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/practice/presentation/practice_folders.dart';

void main() {
  for (final size in [
    const Size(320, 600),
    const Size(800, 400),
    const Size(800, 1000),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('folders open and select at $size scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <PracticeAction>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: SaberPlusTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: PracticeFolders(onOpen: opened.add)),
          ),
        );
        final folder = find.byKey(const Key('practice-folder-games'));
        await tester.ensureVisible(folder);
        await tester.tap(folder);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('practice-folder-dialog-games')),
          findsOneWidget,
        );
        expect(opened, isEmpty);
        final action = find.byKey(const Key('open-summit'));
        await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(opened.single.path, '/student/practice/summit');
        expect(find.byType(PracticeFolderDialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('folder closes with X, outside and back', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeFolders(onOpen: (_) => fail('unexpected navigation')),
        ),
      ),
    );
    for (final close in ['x', 'outside', 'back']) {
      await tester.tap(find.byKey(const Key('practice-folder-priorities')));
      await tester.pumpAndSettle();
      if (close == 'x') {
        await tester.tap(find.byKey(const Key('close-practice-folder')));
      } else if (close == 'outside') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(PracticeFolderDialog), findsNothing);
    }
  });
}
