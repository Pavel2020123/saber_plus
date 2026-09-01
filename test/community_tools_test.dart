import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/announcements/domain/announcement_models.dart';
import 'package:saber_plus/features/announcements/domain/announcement_repository.dart';
import 'package:saber_plus/features/announcements/presentation/announcement_providers.dart';
import 'package:saber_plus/features/announcements/presentation/announcements_page.dart';
import 'package:saber_plus/features/referrals/domain/referral_models.dart';
import 'package:saber_plus/features/score_calculator/domain/icfes_score_calculator.dart';
import 'package:saber_plus/features/score_calculator/presentation/score_calculator_page.dart';
import 'package:saber_plus/features/support/domain/support_configuration.dart';

void main() {
  test('calcula el global con las ponderaciones oficiales', () {
    expect(
      IcfesScoreCalculator.globalScore(
        const IcfesAreaScores(
          criticalReading: 100,
          mathematics: 100,
          socialSciences: 100,
          naturalSciences: 100,
          english: 100,
        ),
      ),
      500,
    );
    expect(
      IcfesScoreCalculator.globalScore(
        const IcfesAreaScores(
          criticalReading: 70,
          mathematics: 80,
          socialSciences: 60,
          naturalSciences: 75,
          english: 50,
        ),
      ),
      348,
    );
  });

  test('rechaza un puntaje por prueba fuera del rango', () {
    expect(
      IcfesScoreCalculator.globalScore(
        const IcfesAreaScores(
          criticalReading: 101,
          mathematics: 80,
          socialSciences: 60,
          naturalSciences: 75,
          english: 50,
        ),
      ),
      isNull,
    );
  });

  test('solo acepta el enlace exacto y cifrado de WhatsApp', () {
    final trusted = SupportConfiguration.fromJson({
      'activo': true,
      'numeroWhatsapp': '573001234567',
      'mensajeWhatsapp': 'Hola',
      'whatsappUrl': 'https://wa.me/573001234567?text=Hola',
    });
    final lookalike = SupportConfiguration.fromJson({
      'activo': true,
      'mensajeWhatsapp': 'Hola',
      'whatsappUrl': 'https://wa.me.ejemplo.com/573001234567',
    });

    expect(trusted.trustedWhatsappUri, isNotNull);
    expect(lookalike.trustedWhatsappUri, isNull);
  });

  test('interpreta referidos sin depender de saldos o identidades', () {
    final summary = ReferralSummary.fromJson({
      'codigo': 'SABER123',
      'totalInvitaciones': 1,
      'invitaciones': [
        {
          'id': 'invitation-1',
          'nombre': 'Dato que la app no modela',
          'fechaRegistro': '2026-08-31T12:00:00.000Z',
        },
      ],
      'beneficio': {'estado': 'POR_DEFINIR', 'descripcion': 'Próximamente'},
    });

    expect(summary.code, 'SABER123');
    expect(summary.invitations.single.id, 'invitation-1');
    expect(summary.shareText, contains('SABER123'));
    expect(summary.benefit.isPendingDefinition, isTrue);
  });

  testWidgets('calcula y restablece el puntaje desde la interfaz', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScoreCalculatorPage()));

    for (final key in const [
      'score-critical-reading',
      'score-mathematics',
      'score-social-sciences',
      'score-natural-sciences',
      'score-english',
    ]) {
      final field = find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '100');
    }
    await tester.drag(
      find.byKey(const Key('score-calculator-list')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calculate-global-score')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-score-result')), findsOneWidget);
    expect(find.text('500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-score-calculator')));
    await tester.pump();
    expect(find.byKey(const Key('global-score-result')), findsNothing);
  });

  testWidgets('marca anuncios individuales y en lote', (tester) async {
    final repository = _FakeAnnouncementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AnnouncementsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 pendientes'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('mark-announcement-announcement-1-read')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 pendiente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-all-announcements-read')));
    await tester.pumpAndSettle();
    expect(find.text('0 pendientes'), findsOneWidget);
    expect(repository.markedAll, isTrue);
  });
}

class _FakeAnnouncementRepository implements AnnouncementRepository {
  var markedAll = false;
  late AnnouncementBoard board = AnnouncementBoard.fromJson({
    'pendientes': 2,
    'anuncios': [
      for (var index = 1; index <= 2; index++)
        {
          'id': 'announcement-$index',
          'titulo': 'Anuncio $index',
          'contenido': 'Contenido seguro',
          'tipo': 'INFORMACION',
          'origen': 'SABERPLUS',
          'fechaInicio': '2026-08-31T12:00:00.000Z',
          'fechaFin': null,
          'destacado': false,
          'leido': false,
          'fechaLectura': null,
        },
    ],
  });

  @override
  Future<AnnouncementBoard> load() async => board;

  @override
  Future<void> markAllRead() async {
    markedAll = true;
    board = board.markAllRead(DateTime.now());
  }

  @override
  Future<DateTime> markRead(String id) async {
    final now = DateTime.now();
    board = board.markRead(id, now);
    return now;
  }
}
