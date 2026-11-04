import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/presentation_mode.dart';
import 'package:saber_plus/features/practice/presentation/practice_hub_page.dart';
import 'package:saber_plus/features/practice/presentation/practice_folders.dart';

void main() {
  const selected = {'open-summit', 'open-star-rescue', 'open-guardian'};
  const additional = {
    'open-trivia-rush',
    'open-ghost-duel',
    'open-tug-of-war',
    'open-async-battles',
  };

  test('normal application does not opt into presentation restrictions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(presentationModeProvider), isFalse);
  });

  for (final presentation in [false, true]) {
    testWidgets(
      'presentation=$presentation preserves learning and selects games',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              presentationModeProvider.overrideWithValue(presentation),
            ],
            child: const MaterialApp(home: PracticeHubPage()),
          ),
        );
        final keys = practiceFolders(
          presentation: presentation,
        ).expand((folder) => folder.actions).map((action) => action.id).toSet();
        expect(keys, containsAll(selected));
        expect(keys, isNot(contains('open-memory-match')));
        expect(keys, contains('open-teacher-priorities'));
        expect(
          keys.where((key) => key.startsWith('practice-area-')),
          hasLength(5),
        );
        for (final key in additional) {
          expect(keys.contains(key), !presentation, reason: key);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
