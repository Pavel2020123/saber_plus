import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/academic_image_viewer.dart';
import 'package:saber_plus/features/auth/presentation/welcome_page.dart';

void main() {
  testWidgets('welcome retains logo without visible brand text', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    expect(find.text('SaberPlus'), findsNothing);
    expect(find.byIcon(Icons.auto_stories_rounded), findsWidgets);
    expect(find.text('Comenzar'), findsOneWidget);
  });
  testWidgets('viewer fits narrow screen with large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const AcademicImageViewer(
          label: 'Una imagen con una descripción larga',
          child: ColoredBox(color: Colors.blue),
        ),
      ),
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
