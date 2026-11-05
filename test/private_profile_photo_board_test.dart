import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/profile/domain/private_profile_photo.dart';
import 'package:saber_plus/features/profile/presentation/private_profile_photo_board.dart';

const id = '2df4f385-fec2-4cb1-89af-91f67a476b52';
final pixels = base64Decode(
  'UklGRlgAAABXRUJQVlA4IEwAAADwBACdASp4ADwAPm02mUmkIyKhIQgAgA2JaQB2APwAABPPNPcaiVea2vp06dOnRwAA/us2///1aHy0Plofuff//mCV+QbrkAAAAAAA',
);

class PhotoFake implements PrivateProfilePhotoRepository {
  PrivateProfilePhoto photo = const PrivateProfilePhoto(revision: 0);
  final uploads = <(String, int, Uint8List)>[];
  final receipts = <String, PrivatePhotoReceipt>{};
  bool loseUpload = false,
      failUpload = false,
      loseRemoval = false,
      failContent = false;
  int removals = 0;
  Completer<PrivateProfilePhoto>? pendingLoad;
  @override
  Future<PrivateProfilePhoto> load() async => pendingLoad?.future ?? photo;
  @override
  Future<Uint8List> content(PrivateProfilePhoto photo) async {
    if (failContent) throw Exception('synthetic unavailable image');
    return pixels;
  }

  @override
  Future<PrivatePhotoReceipt> upload(
    String operation,
    int revision,
    Uint8List bytes,
  ) async {
    uploads.add((operation, revision, bytes));
    if (failUpload) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Synthetic timeout',
      );
    }
    photo = PrivateProfilePhoto(revision: revision + 1, fileId: id);
    final receipt = PrivatePhotoReceipt(
      id: id,
      operationId: operation,
      state: PrivatePhotoOperationState.active,
      photo: photo,
      cleanupPending: false,
    );
    receipts[operation] = receipt;
    if (loseUpload) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Synthetic lost response',
      );
    }
    return receipt;
  }

  @override
  Future<PrivatePhotoReceipt> operation(String operation) async {
    if (!receipts.containsKey(operation)) {
      throw const ApiError(code: '404', message: 'No receipt');
    }
    return receipts[operation]!;
  }

  @override
  Future<PrivatePhotoReceipt> cancel(String operation) async =>
      PrivatePhotoReceipt(
        id: id,
        operationId: operation,
        state: PrivatePhotoOperationState.retired,
        photo: photo,
        cleanupPending: false,
      );
  @override
  Future<PrivatePhotoRemoval> remove(int revision) async {
    removals++;
    photo = PrivateProfilePhoto(revision: revision + 1);
    if (loseRemoval) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Synthetic lost response',
      );
    }
    return PrivatePhotoRemoval(photo, false);
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    PhotoFake repo, {
    String owner = 'self',
    Future<Uint8List?> Function()? pick,
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? SaberPlusTheme.dark
            : SaberPlusTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: PrivateProfilePhotoBoard(
          userId: owner,
          repository: repo,
          pick: pick ?? () async => pixels,
        ),
      ),
    );
    if (repo.pendingLoad == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      await tester.pumpAndSettle();
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('private-photo-pick')));
  Future<void> save(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('private-photo-save')));

  testWidgets(
    'own-only explanation and selecting never uploads automatically',
    (tester) async {
      final repo = PhotoFake();
      await pump(tester, repo);
      expect(find.textContaining('Solo tú puedes verla'), findsOneWidget);
      await select(tester);
      expect(find.text('Selección sin guardar'), findsOneWidget);
      expect(repo.uploads, isEmpty);
      await save(tester);
      expect(repo.uploads, hasLength(1));
      expect(find.text('Tu foto privada quedó guardada.'), findsOneWidget);
    },
  );

  testWidgets('gallery cancellation leaves the stored state unchanged', (
    tester,
  ) async {
    final repo = PhotoFake();
    await pump(tester, repo, pick: () async => null);
    await select(tester);
    expect(find.text('Selección sin guardar'), findsNothing);
    expect(repo.uploads, isEmpty);
  });

  testWidgets('selection can be discarded without any server mutation', (
    tester,
  ) async {
    final repo = PhotoFake();
    await pump(tester, repo);
    await select(tester);
    await tap(tester, find.text('Descartar selección'));
    expect(find.text('Selección sin guardar'), findsNothing);
    expect(repo.uploads, isEmpty);
  });

  testWidgets(
    'lost positive upload is recovered by receipt without duplicating upload',
    (tester) async {
      final repo = PhotoFake()..loseUpload = true;
      await pump(tester, repo);
      await select(tester);
      await save(tester);
      expect(find.text('Consultar estado de la carga'), findsOneWidget);
      expect(find.text('Tu foto privada quedó guardada.'), findsNothing);
      await tap(tester, find.byKey(const Key('private-photo-receipt')));
      expect(find.text('Tu foto privada quedó guardada.'), findsOneWidget);
      expect(repo.uploads, hasLength(1));
    },
  );

  testWidgets(
    'retry keeps the same operation, revision and bytes; 404 is not cancellation',
    (tester) async {
      final repo = PhotoFake()..failUpload = true;
      await pump(tester, repo);
      await select(tester);
      await save(tester);
      await tap(tester, find.byKey(const Key('private-photo-receipt')));
      expect(find.textContaining('Eso no confirma'), findsOneWidget);
      await save(tester);
      expect(repo.uploads, hasLength(2));
      expect(repo.uploads[0].$1, repo.uploads[1].$1);
      expect(repo.uploads[0].$2, repo.uploads[1].$2);
      expect(repo.uploads[0].$3, repo.uploads[1].$3);
      expect(find.text('Tu foto privada quedó guardada.'), findsNothing);
    },
  );

  testWidgets('confirmed cancellation removes a pending selection', (
    tester,
  ) async {
    final repo = PhotoFake()..failUpload = true;
    await pump(tester, repo);
    await select(tester);
    await save(tester);
    await tap(tester, find.text('Cancelar carga pendiente'));
    expect(find.text('La carga pendiente quedó cancelada.'), findsOneWidget);
    expect(find.text('Selección sin guardar'), findsNothing);
  });

  testWidgets(
    'removal requires confirmation and a lost response hides the old image',
    (tester) async {
      final repo = PhotoFake()
        ..photo = const PrivateProfilePhoto(revision: 1, fileId: id);
      await pump(tester, repo);
      await tap(tester, find.byKey(const Key('private-photo-remove')));
      await tap(tester, find.text('Cancelar'));
      expect(repo.removals, 0);
      repo.loseRemoval = true;
      await tap(tester, find.byKey(const Key('private-photo-remove')));
      await tap(tester, find.widgetWithText(FilledButton, 'Quitar foto'));
      expect(find.text('Retirada sin confirmar'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await tap(tester, find.text('Comprobar retirada'));
      expect(find.text('La retirada quedó confirmada.'), findsOneWidget);
    },
  );

  testWidgets(
    'an acknowledged upload is not retried just because its preview failed',
    (tester) async {
      final repo = PhotoFake()..failContent = true;
      await pump(tester, repo);
      await select(tester);
      await save(tester);
      expect(find.textContaining('quedó guardada.'), findsOneWidget);
      expect(find.text('Consultar estado de la carga'), findsNothing);
      expect(find.text('Selección sin guardar'), findsNothing);
      expect(repo.uploads, hasLength(1));
    },
  );

  testWidgets(
    'account replacement discards delayed load from the previous owner',
    (tester) async {
      final first = PhotoFake()..pendingLoad = Completer<PrivateProfilePhoto>();
      await pump(tester, first, owner: 'first');
      final second = PhotoFake();
      await pump(tester, second, owner: 'second');
      first.pendingLoad!.complete(
        const PrivateProfilePhoto(revision: 1, fileId: id),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin foto todavía'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account replacement discards delayed gallery selection', (
    tester,
  ) async {
    final selected = Completer<Uint8List?>();
    await pump(
      tester,
      PhotoFake(),
      owner: 'first',
      pick: () => selected.future,
    );
    await tester.tap(find.byKey(const Key('private-photo-pick')));
    await tester.pump();
    await pump(tester, PhotoFake(), owner: 'second');
    selected.complete(pixels);
    await tester.pumpAndSettle();
    expect(find.text('Selección sin guardar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(375, 812),
    const Size(812, 375),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('large text and reduced motion fit $size $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(tester, PhotoFake(), scale: 2.5, brightness: brightness);
        await select(tester);
        await save(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
