import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saber_plus/core/media/private_lesson_cache.dart';
import 'package:saber_plus/core/media/private_offline_access_policy.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/features/study/presentation/private_lesson_page.dart';

// Dedicated test entrypoint; never enables a driver in the production app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final vault = AndroidPrivateLessonVault();
  const owner = 'p3_native_synthetic_owner';
  setUp(() async => vault.clearAccount(owner));
  tearDown(() async => vault.clearAccount(owner));

  testWidgets('Owned HTTP validation, native offline copy and confirmed revocation', (
    tester,
  ) async {
    const base = String.fromEnvironment('P3_API');
    const context = String.fromEnvironment('P3_CONTEXT');
    const account = String.fromEnvironment('P3_OWNER');
    const password = String.fromEnvironment('P3_PASSWORD');
    const fileId = String.fromEnvironment('P3_FILE');
    expect(base, 'http://127.0.0.1:43188');
    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final admin = Dio(BaseOptions(baseUrl: base));
    final tokens = AccessTokenStore();
    final cache = PrivateLessonCache(dio, tokens, vault);
    await vault.clearAccount(account);
    try {
      final login = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'correo': 'student@example.invalid', 'contrasena': password},
      );
      final token = login.data!['accessToken'] as String;
      tokens.set(token);
      dio.options.headers['Authorization'] = 'Bearer $token';
      cache.setAccount(account);
      final fresh = await cache.open(context);
      expect(fresh.image, isNotEmpty);
      expect(fresh.remaining.inHours, inInclusiveRange(71, 72));
      dio.options.baseUrl =
          'http://127.0.0.1:43189'; // No listener: real connection failure, no mock adapter.
      final offline = await cache.open(context);
      expect(offline.content, fresh.content);
      expect(offline.remaining <= fresh.remaining, isTrue);
      dio.options.baseUrl = base;
      final adminLogin = await admin.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'correo': 'admin@example.invalid', 'contrasena': password},
      );
      admin.options.headers['Authorization'] =
          'Bearer ${adminLogin.data!['accessToken']}';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [privateLessonCacheProvider.overrideWith((ref) => cache)],
          child: MaterialApp(home: PrivateLessonPage(contextId: context)),
        ),
      );
      for (
        var i = 0;
        i < 80 && find.text(fresh.content).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(fresh.content), findsOneWidget);
      final operation =
          DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(32, '0');
      final uuid =
          '${operation.substring(0, 8)}-${operation.substring(8, 12)}-4${operation.substring(13, 16)}-a${operation.substring(17, 20)}-${operation.substring(20)}';
      await admin.post(
        '/admin/archivos/$fileId/revocaciones',
        data: {
          'operacionId': uuid,
          'motivo': 'DERECHOS',
          'detalle': 'Ensayo sintético C5-P3 USB',
        },
      );
      await expectLater(
        cache.open(context),
        throwsA(isA<PrivateLessonUnavailable>()),
      );
      await tester.pumpAndSettle();
      expect(find.text(fresh.content), findsNothing);
      expect(await vault.read(account, context), isNull);
      await tester.pumpWidget(
        const SizedBox(),
      ); // Provider owns and disposes cache.
    } finally {
      await vault.clearAccount(account);
      dio.close(force: true);
      admin.close(force: true);
    }
  }, skip: !const bool.fromEnvironment('P3_LOCAL_OWNED_TEST'));

  testWidgets(
    'Android stores ciphertext, rejects tampering and copied contexts',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final root = Directory(
        p.join(p.dirname(support.path), 'no_backup', 'private_offline_v1'),
      );
      String digest(String value) =>
          sha256.convert(utf8.encode(value)).toString();
      File record(String context) =>
          File(p.join(root.path, '${digest(owner)}_${digest(context)}.bin'));
      const secret = 'p3-synthetic-sensitive-text-never-cleartext';
      await vault.seal(owner, 'original', secret, await vault.clock());
      final file = record('original');
      final bytes = await file.readAsBytes();
      expect(latin1.decode(bytes), isNot(contains(secret)));
      await file.copy(record('copied').path);
      await expectLater(
        vault.read(owner, 'copied'),
        throwsA(isA<PlatformException>()),
      );
      bytes[bytes.length - 1] ^= 1;
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(
        vault.read(owner, 'original'),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  testWidgets('Android Keystore encrypted roundtrip and account isolation', (
    tester,
  ) async {
    final anchor = await vault.clock();
    expect(anchor.bootId, isNotEmpty);
    expect(anchor.elapsed, greaterThanOrEqualTo(Duration.zero));
    await vault.seal(owner, 'lesson', 'synthetic private text', anchor);
    final copy = await vault.read(owner, 'lesson');
    expect(copy?.payload, 'synthetic private text');
    expect(
      copy!.remainingMs,
      inInclusiveRange(1, const Duration(hours: 72).inMilliseconds),
    );
    expect(await vault.read('p3_other_owner', 'lesson'), isNull);
    expect(await vault.read(owner, 'other_lesson'), isNull);
    await vault.clearContext(owner, 'lesson');
    expect(await vault.read(owner, 'lesson'), isNull);
  });

  testWidgets('Android refuses foreign boot and future monotonic anchors', (
    tester,
  ) async {
    final anchor = await vault.clock();
    await expectLater(
      vault.seal(
        owner,
        'lesson',
        'blocked',
        OfflineClockSample(
          bootId: '${anchor.bootId}_foreign',
          elapsed: anchor.elapsed,
        ),
      ),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      vault.seal(
        owner,
        'lesson',
        'blocked',
        OfflineClockSample(
          bootId: anchor.bootId,
          elapsed: anchor.elapsed + const Duration(days: 1),
        ),
      ),
      throwsA(isA<PlatformException>()),
    );
    expect(await vault.read(owner, 'lesson'), isNull);
  });

  testWidgets('Android account cleanup invalidates every package', (
    tester,
  ) async {
    final anchor = await vault.clock();
    await vault.seal(owner, 'one', 'synthetic one', anchor);
    await vault.seal(owner, 'two', 'synthetic two', anchor);
    await vault.clearAccount(owner);
    expect(await vault.read(owner, 'one'), isNull);
    expect(await vault.read(owner, 'two'), isNull);
    await vault.seal(
      owner,
      'one',
      'new key after cleanup',
      await vault.clock(),
    );
    expect((await vault.read(owner, 'one'))?.payload, 'new key after cleanup');
  });
}
