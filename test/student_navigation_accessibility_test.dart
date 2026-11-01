import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/shared/presentation/student_shell.dart';

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets(
      'student navigation preserves accessible names at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = 3;
        await tester.pumpWidget(
          MaterialApp(
            theme: SaberPlusTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              bottomNavigationBar: StudentNavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (index) => selected = index,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(
          bar.labelBehavior,
          scale == 1
              ? NavigationDestinationLabelBehavior.alwaysShow
              : NavigationDestinationLabelBehavior.onlyShowSelected,
        );
        expect(
          bar.destinations.cast<NavigationDestination>().map((d) => d.label),
          ['Inicio', 'Estudiar', 'Practicar', 'Progreso', 'Más'],
        );
        expect(find.byTooltip('Estudiar'), findsOneWidget);
        await tester.tap(find.byType(NavigationDestination).at(1));
        expect(selected, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
